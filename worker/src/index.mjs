/**
 * "Ask Mira" AI proxy for Pregnancy Companion — a Cloudflare Worker (free tier).
 *
 * Uses Google's **Gemini** API, which has a genuinely free tier (Google AI
 * Studio), so the whole feature costs nothing at low volume: free hosting
 * (Cloudflare) + free Firebase (Spark) + free Gemini tier.
 *
 * It holds the Gemini API key server-side and mirrors the app's old contract:
 *  - verifies the caller's Firebase ID token (only signed-in app users may call),
 *  - builds a safety-first system prompt with lightweight pregnancy context,
 *  - proxies the Gemini generateContent API, and returns { reply, model, refused? }.
 *
 * Secrets/vars (see wrangler.toml + README):
 *  - GEMINI_API_KEY  (secret)  — `wrangler secret put GEMINI_API_KEY`
 *  - FIREBASE_PROJECT_ID (var) — the Firebase project id, for token audience
 *  - MODEL (var, optional)     — defaults to gemini-2.0-flash (a free-tier model)
 */

const MAX_MESSAGES = 20; // cap conversation history sent upstream
const MAX_CHARS = 4000; // cap per-message length

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }
    if (request.method !== 'POST') {
      return json({ error: 'Method not allowed.' }, 405);
    }

    // --- Auth: require a valid Firebase ID token ---
    const authz = request.headers.get('Authorization') || '';
    const token = authz.startsWith('Bearer ') ? authz.slice(7) : '';
    if (!token) return json({ error: 'Sign in to use the assistant.' }, 401);
    let callerUid = '';
    try {
      const claims = await verifyFirebaseIdToken(token, env.FIREBASE_PROJECT_ID);
      callerUid = claims.sub;
    } catch (_) {
      return json({ error: 'Invalid or expired session.' }, 401);
    }

    // --- Parse + validate the conversation ---
    let body;
    try {
      body = await request.json();
    } catch (_) {
      return json({ error: 'Invalid JSON body.' }, 400);
    }

    // Optional: the user's OWN Gemini API key (their own free-tier quota).
    // When present it overrides the shared server key FOR THIS REQUEST ONLY, so
    // heavy users never hit a shared limit. Everything else (Firebase project,
    // Cloudflare AI binding) is preserved.
    const userKey =
      (body && typeof body.userKey === 'string' && body.userKey.trim()) || '';
    const aenv = userKey ? { ...env, GEMINI_API_KEY: userKey } : env;

    // --- Document vision tasks (prescription scan / lab report analysis) ---
    const task = body && typeof body.task === 'string' ? body.task : 'chat';

    // --- Admin (service-account) operations ---
    if (task === 'admin_delete_user' || task === 'admin_disable_user') {
      return handleAdminUser(task, body, callerUid, env);
    }

    if (task === 'prescription' || task === 'lab') {
      return handleVision(task, body, aenv);
    }
    if (task === 'baby_predict') {
      return handleBabyPredict(body, aenv);
    }
    if (['medicine_info', 'symptom_check', 'meal_plan', 'weekly_summary', 'interactions', 'wellness_plan', 'baby_names', 'myth_explain', 'myth_of_day', 'wellbeing'].includes(task)) {
      return handleTextTask(task, body, aenv);
    }

    let messages;
    try {
      messages = sanitizeMessages(body && body.messages);
    } catch (e) {
      return json({ error: e.message }, 400);
    }
    const system = buildSystemPrompt(body && body.context, body && body.lang);

    // --- Proxy the Gemini generateContent API ---
    const model = env.MODEL || 'gemini-flash-latest';
    // Gemini uses role "model" for the assistant, and { parts: [{ text }] }.
    const contents = messages.map((m) => ({
      role: m.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: m.content }],
    }));

    const upstream = await geminiFetch(
      model,
      {
        system_instruction: { parts: [{ text: system }] },
        contents,
        generationConfig: { maxOutputTokens: 1024, temperature: 0.7 },
        // A pregnancy app must be able to discuss symptoms; relax the
        // filters to "only high" so legitimate medical talk isn't blocked.
        safetySettings: [
          'HARM_CATEGORY_HARASSMENT',
          'HARM_CATEGORY_HATE_SPEECH',
          'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'HARM_CATEGORY_DANGEROUS_CONTENT',
        ].map((category) => ({ category, threshold: 'BLOCK_ONLY_HIGH' })),
      },
      aenv,
    );

    let reply = '';
    if (upstream && upstream.ok) {
      const data = await upstream.json();
      // Safety block (prompt-level or candidate-level) → graceful refusal.
      const blocked =
        (data.promptFeedback && data.promptFeedback.blockReason) ||
        (data.candidates &&
          data.candidates[0] &&
          data.candidates[0].finishReason === 'SAFETY');
      if (blocked) {
        return json({
          reply:
            "I'm sorry, I can't help with that. If this is about your health, " +
            'please reach out to your doctor.',
          model,
          refused: true,
        });
      }
      const parts =
        (data.candidates &&
          data.candidates[0] &&
          data.candidates[0].content &&
          data.candidates[0].content.parts) ||
        [];
      reply = parts.map((p) => (typeof p.text === 'string' ? p.text : '')).join('').trim();
    } else {
      // Gemini free quota exhausted → free fallback provider (Cloudflare AI).
      const lastUser = messages[messages.length - 1];
      reply = (await cfFallbackText(aenv, {
            system,
            user: (lastUser && lastUser.content) || '',
          })) ||
          '';
      if (!reply) {
        const status = upstream ? upstream.status : 0;
        return json(
          {
            error: status === 429
              ? 'The assistant is busy right now (free-tier limit). Please try again shortly.'
              : 'The assistant is unavailable right now. Please try again.',
          },
          502,
        );
      }
    }

    return json({
      reply: reply || "I'm not sure how to answer that — could you rephrase?",
      model,
    });
  },
};

// --------------------------- document vision (prescription / lab) ---------------------------

const VISION_MIME = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
  'application/pdf',
];
// ~10MB of base64 (~7.5MB decoded) upload cap.
const MAX_IMAGE_B64 = 10 * 1024 * 1024;

/// Handles a single-image/PDF analysis request. Sends the document inline to
/// Gemini (multimodal) with a task-specific, safety-first prompt and asks for a
/// strict JSON result which we parse and return as { task, model, result }.
async function handleVision(task, body, env) {
  const image = body && body.image;
  const mimeType = image && typeof image.mimeType === 'string' ? image.mimeType : '';
  const data = image && typeof image.data === 'string' ? image.data : '';

  if (!data || !VISION_MIME.includes(mimeType)) {
    return json({ error: 'Attach a clear photo or PDF (JPG, PNG, WebP or PDF).' }, 400);
  }
  if (data.length > MAX_IMAGE_B64) {
    return json({ error: 'That file is too large. Please use a smaller photo.' }, 413);
  }

  const model = env.MODEL || 'gemini-flash-latest';
  const built = buildVisionPrompt(task);
  const system = built.system + _langDirective(body && body.lang, true);
  const instruction = built.instruction;

  const payload = {
    system_instruction: { parts: [{ text: system }] },
    contents: [
      {
        role: 'user',
        parts: [
          { text: instruction },
          { inline_data: { mime_type: mimeType, data } },
        ],
      },
    ],
    generationConfig: {
      // Prescriptions/labs can list many rows; a low cap truncates the
      // JSON and makes parsing fail. Give plenty of room.
      maxOutputTokens: 8192,
      temperature: 0.1,
      responseMimeType: 'application/json',
    },
    safetySettings: [
      'HARM_CATEGORY_HARASSMENT',
      'HARM_CATEGORY_HATE_SPEECH',
      'HARM_CATEGORY_SEXUALLY_EXPLICIT',
      'HARM_CATEGORY_DANGEROUS_CONTENT',
    ].map((category) => ({ category, threshold: 'BLOCK_ONLY_HIGH' })),
  };

  // Retry transient 429/5xx + model fallback (free tier), like the text tasks.
  const upstream = await geminiFetch(model, payload, env);

  let text = '';
  if (upstream && upstream.ok) {
    const resp = await upstream.json();
    const blocked =
      (resp.promptFeedback && resp.promptFeedback.blockReason) ||
      (resp.candidates && resp.candidates[0] &&
        resp.candidates[0].finishReason === 'SAFETY');
    if (blocked) {
      return json(
        { error: 'I could not analyze that safely. Please consult your doctor.', refused: true },
        200,
      );
    }
    const parts =
      (resp.candidates &&
        resp.candidates[0] &&
        resp.candidates[0].content &&
        resp.candidates[0].content.parts) ||
      [];
    text = parts.map((p) => (typeof p.text === 'string' ? p.text : '')).join('').trim();
  } else {
    // Gemini free quota exhausted → free fallback provider (Cloudflare AI vision).
    text = (await cfFallbackText(env, {
          system,
          user: instruction,
          image: { data },
        })) ||
        '';
    if (!text) {
      const status = upstream ? upstream.status : 0;
      const msg = status === 429
        ? 'The analyzer is busy right now (free-tier limit). Please try again in a little while.'
        : 'The analyzer is unavailable right now. Please try again.';
      return json({ error: msg }, 502);
    }
  }

  const result = parseJsonLenient(text);
  if (result == null) {
    return json(
      { error: 'Could not read the document clearly. Please try a clearer photo.' },
      422,
    );
  }
  return json({ task, model, result });
}

/// Baby-face predictor (for-fun novelty): takes the mother's + father's photos
/// and asks Gemini's image model to imagine a baby blending their features.
/// Returns { task, image: { mimeType, data(base64) } } or a clear error.
async function handleBabyPredict(body, env) {
  const mother = body && body.mother;
  const father = body && body.father;
  const imgs = [mother, father].filter(
    (x) => x && typeof x.data === 'string' && VISION_MIME.includes(x.mimeType),
  );
  if (imgs.length < 2) {
    return json({ error: 'Please add a clear photo of both parents.' }, 400);
  }
  for (const im of imgs) {
    if (im.data.length > MAX_IMAGE_B64) {
      return json({ error: 'A photo is too large. Use smaller photos.' }, 413);
    }
  }

  // Image-generation model ("nano banana"). Overridable via IMAGE_MODEL.
  const model =
    (body && typeof body.imageModel === 'string' && body.imageModel) ||
    env.IMAGE_MODEL ||
    'gemini-2.5-flash-image';
  const prompt =
    'From these two photos of two adults (a mother and a father), imagine and ' +
    'GENERATE a single new, photorealistic portrait of what their baby might ' +
    'look like as a happy, healthy infant (around 6-12 months old), softly ' +
    'blending facial features from both. Warm, gentle lighting, plain soft ' +
    'background, cute and wholesome. Output an image.';

  let upstream;
  try {
    upstream = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-goog-api-key': env.GEMINI_API_KEY,
        },
        body: JSON.stringify({
          contents: [
            {
              role: 'user',
              parts: [
                { text: prompt },
                { inline_data: { mime_type: imgs[0].mimeType, data: imgs[0].data } },
                { inline_data: { mime_type: imgs[1].mimeType, data: imgs[1].data } },
              ],
            },
          ],
          generationConfig: { responseModalities: ['IMAGE'] },
          safetySettings: [
            'HARM_CATEGORY_HARASSMENT',
            'HARM_CATEGORY_HATE_SPEECH',
            'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'HARM_CATEGORY_DANGEROUS_CONTENT',
          ].map((category) => ({ category, threshold: 'BLOCK_ONLY_HIGH' })),
        }),
      },
    );
  } catch (_) {
    return json({ error: 'The baby preview is unavailable right now.' }, 502);
  }

  if (!upstream.ok) {
    const status = upstream.status;
    let detail = '';
    try {
      detail = (await upstream.text()).slice(0, 300);
    } catch (_) {}
    const msg = status === 429
      ? 'The baby preview is busy right now. Please try again in a moment.'
      : status === 404
        ? 'Baby preview is not available on this plan yet.'
        : 'The baby preview is unavailable right now.';
    return json({ error: msg, _status: status, _detail: detail }, 502);
  }

  const resp = await upstream.json();
  const parts =
    (resp.candidates &&
      resp.candidates[0] &&
      resp.candidates[0].content &&
      resp.candidates[0].content.parts) ||
    [];
  const imgPart = parts.find((p) => p.inlineData || p.inline_data);
  const inline = imgPart && (imgPart.inlineData || imgPart.inline_data);
  if (!inline || !inline.data) {
    return json({ error: 'Could not create a baby preview from those photos.' }, 422);
  }
  return json({
    task: 'baby_predict',
    image: { mimeType: inline.mimeType || inline.mime_type || 'image/png', data: inline.data },
  });
}

/// System + user prompts for each document task. Extraction only — never
/// diagnosis or a treatment plan.
function buildVisionPrompt(task) {
  if (task === 'prescription') {
    return {
      system:
        'You are a careful assistant that reads doctor prescriptions for an ' +
        'India-first pregnancy app. Extract ONLY what is actually written — never ' +
        'invent medicines, doses or timings. You do not give medical advice about ' +
        'the medicines; you only transcribe them into structured data for the ' +
        'mother to review and confirm.',
      instruction:
        'Read this prescription (image or PDF) carefully. It may be a phone photo ' +
        'taken at an angle, low light, or contain handwriting — read ALL visible ' +
        'text (printed and handwritten), mentally de-rotate if needed, and ' +
        'transcribe what you can even if some fields are unclear. Extract the ' +
        'prescribed medicines. Respond with ONLY a JSON object of exactly this shape:\n' +
        '{\n' +
        '  "isPrescription": boolean,\n' +
        '  "medicines": [\n' +
        '    {\n' +
        '      "name": string,\n' +
        '      "dosage": string,\n' +
        '      "timesPerDay": number,\n' +
        '      "suggestedTimes": [string],\n' +
        '      "timing": "beforeFood" | "afterFood" | "anytime",\n' +
        '      "durationDays": number | null,\n' +
        '      "instructions": string\n' +
        '    }\n' +
        '  ],\n' +
        '  "warnings": [string]\n' +
        '}\n' +
        'Rules: "suggestedTimes" are 24-hour "HH:mm" clock times spreading ' +
        'timesPerDay across the day (1 -> ["09:00"], 2 -> ["09:00","21:00"], ' +
        '3 -> ["08:00","14:00","20:00"], 4 -> ["08:00","12:00","16:00","20:00"]). ' +
        'Use "dosage" for strength/quantity like "500 mg" or "1 tablet". If a ' +
        'field is unknown use null, 0, or "". If this is NOT a prescription, set ' +
        '"isPrescription" false and "medicines" to []. Put anything unclear or ' +
        'important to double-check into "warnings". Output JSON only, no prose.',
    };
  }
  // lab
  return {
    system:
      'You are a warm, careful assistant that explains medical lab / test ' +
      'reports in simple language for an expecting mother in India. You are NOT a ' +
      'doctor: you never diagnose, prescribe, or give a treatment plan. You ' +
      'explain what the values mean, gently flag anything outside the normal ' +
      'range, and always advise confirming with her own doctor.',
    instruction:
      'Read this lab/test report (image or PDF) carefully. It may be a phone photo ' +
      'at an angle or with glare — read ALL visible rows of the results table, ' +
      'including the test name, value, unit and reference range for each, and ' +
      'transcribe every value you can make out. Respond with ONLY a JSON object ' +
      'of exactly this shape:\n' +
      '{\n' +
      '  "reportType": string,\n' +
      '  "summary": string,\n' +
      '  "findings": [\n' +
      '    {\n' +
      '      "name": string,\n' +
      '      "value": string,\n' +
      '      "unit": string,\n' +
      '      "referenceRange": string,\n' +
      '      "status": "low" | "normal" | "high" | "borderline" | "unknown",\n' +
      '      "note": string\n' +
      '    }\n' +
      '  ],\n' +
      '  "recommendations": [string],\n' +
      '  "urgent": boolean,\n' +
      '  "disclaimer": string\n' +
      '}\n' +
      'Keep "summary" to 2-4 plain, reassuring sentences. Set "urgent" true ONLY ' +
      'if a value is dangerously abnormal and she should seek prompt medical care. ' +
      'Always include a short "disclaimer" reminding her this is informational and ' +
      'to confirm with her doctor. If this is not a lab report, set "reportType" to ' +
      '"Unknown" and explain in "summary". Output JSON only, no prose.',
  };
}

/// Generic text-only AI task (no image): builds a task-specific, safety-first
/// prompt, asks Gemini for strict JSON, and returns { task, model, result }.
async function handleTextTask(task, body, env) {
  const built = buildTextPrompt(task, body || {});
  if (built.error) return json({ error: built.error }, 400);

  const model = env.MODEL || 'gemini-flash-latest';
  const system = built.system + _langDirective(body && body.lang, true);
  const payload = {
    system_instruction: { parts: [{ text: system }] },
    contents: [{ role: 'user', parts: [{ text: built.instruction }] }],
    generationConfig: {
      maxOutputTokens: built.maxTokens || 1024,
      temperature: 0.3,
      responseMimeType: 'application/json',
    },
    safetySettings: [
      'HARM_CATEGORY_HARASSMENT',
      'HARM_CATEGORY_HATE_SPEECH',
      'HARM_CATEGORY_SEXUALLY_EXPLICIT',
      'HARM_CATEGORY_DANGEROUS_CONTENT',
    ].map((category) => ({ category, threshold: 'BLOCK_ONLY_HIGH' })),
  };

  let text = '';
  const upstream = await geminiFetch(model, payload, env);
  if (upstream && upstream.ok) {
    const resp = await upstream.json();
    const blocked =
      (resp.promptFeedback && resp.promptFeedback.blockReason) ||
      (resp.candidates && resp.candidates[0] &&
        resp.candidates[0].finishReason === 'SAFETY');
    if (blocked) {
      return json(
        { error: 'I could not help with that safely. Please talk to your doctor.', refused: true },
        200,
      );
    }
    const parts =
      (resp.candidates && resp.candidates[0] && resp.candidates[0].content &&
        resp.candidates[0].content.parts) || [];
    text = parts.map((p) => (typeof p.text === 'string' ? p.text : '')).join('').trim();
  } else {
    // Gemini free quota exhausted → free fallback provider (Cloudflare AI).
    text = (await cfFallbackText(env, {
          system,
          user: built.instruction,
        })) ||
        '';
    if (!text) {
      const status = upstream ? upstream.status : 0;
      const msg = status === 429
        ? 'The assistant is busy right now (free-tier limit). Please try again shortly.'
        : 'This feature is unavailable right now. Please try again.';
      return json({ error: msg }, 503);
    }
  }

  const result = parseJsonLenient(text);
  if (result == null) {
    return json({ error: 'Could not generate that right now. Please try again.' }, 422);
  }
  return json({ task, model, result });
}

/// Calls Gemini generateContent with retry/backoff on transient errors, and —
/// crucially for the free tier — **falls back to an alternate model on 429**.
/// Each Gemini model has its own free-tier quota bucket, so when the primary
/// model's daily/minute quota is exhausted, the lite model usually still works.
async function geminiFetch(model, payload, env, retries = 1) {
  // Try the requested model, then fallbacks with independent free quota.
  const fallbacks = ['gemini-flash-latest', 'gemini-flash-lite-latest'];
  const models = [model, ...fallbacks.filter((m) => m !== model)];
  let last = null;
  for (const m of models) {
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${m}:generateContent`;
    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        const r = await fetch(url, {
          method: 'POST',
          headers: {
            'content-type': 'application/json',
            'x-goog-api-key': env.GEMINI_API_KEY,
          },
          body: JSON.stringify(payload),
        });
        if (r.ok) return r;
        last = r;
        // 429 (quota) → stop retrying this model, move to the next one.
        if (r.status === 429) break;
        // Other non-transient errors → give up (don't burn quota switching).
        if (![500, 502, 503].includes(r.status)) return r;
      } catch (_) {
        last = null;
      }
      if (attempt < retries) {
        await new Promise((res) => setTimeout(res, 600 * (attempt + 1)));
      }
    }
  }
  return last;
}

/// FREE second provider: Cloudflare Workers AI (no external key; runs on the
/// same account as this Worker). Used to recover when Gemini's free-tier quota
/// is exhausted. Returns the generated text, or null if unavailable.
async function cfFallbackText(env, { system, user, image }) {
  if (!env.AI) return null;
  try {
    if (image && typeof image.data === 'string') {
      // Vision model (weaker OCR than Gemini, but better than a hard failure).
      const bin = atob(image.data);
      const bytes = new Array(bin.length);
      for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
      const r = await env.AI.run('@cf/meta/llama-3.2-11b-vision-instruct', {
        prompt: `${system}\n\n${user}\n\nRespond with ONLY valid JSON, no prose.`,
        image: bytes,
        max_tokens: 4096,
      });
      return (r && (r.response || r.description)) || null;
    }
    const r = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user },
      ],
      max_tokens: 2048,
    });
    return (r && r.response) || null;
  } catch (_) {
    return null;
  }
}

const _SAFE =
  'You are a warm, careful assistant inside an India-first pregnancy app. You are ' +
  'NOT a doctor: you never diagnose, prescribe, or change doses. You give general, ' +
  'educational information, keep language simple and reassuring, and always tell ' +
  'her to confirm with her own doctor. If anything suggests an emergency, tell her ' +
  'to seek medical care immediately.';

function _str(v, max = 200) {
  return (typeof v === 'string' ? v : '').trim().slice(0, max);
}

/// Returns { system, instruction, maxTokens } for a text task, or { error }.
function buildTextPrompt(task, body) {
  switch (task) {
    case 'medicine_info': {
      const name = _str(body.name, 120);
      const dosage = _str(body.dosage, 120);
      if (!name) return { error: 'A medicine name is required.' };
      return {
        system: _SAFE + ' Here you explain a medicine for an expecting mother.',
        maxTokens: 1024,
        instruction:
          `Explain the medicine "${name}"${dosage ? ` (dose noted: ${dosage})` : ''} for a ` +
          'pregnant woman. Respond with ONLY JSON: {"name":string,"uses":string,' +
          '"howItWorks":string,"commonSideEffects":[string],"pregnancyNote":string,' +
          '"whenToCallDoctor":[string],"disclaimer":string}. Keep each field short and ' +
          'plain. If the name is unclear, say so in "uses" and leave others empty. JSON only.',
      };
    }
    case 'symptom_check': {
      const symptom = _str(body.symptom, 500);
      if (!symptom) return { error: 'Please describe the symptom.' };
      return {
        system: _SAFE + ' Here you help her understand whether a symptom is common in pregnancy.',
        maxTokens: 1024,
        instruction:
          `A pregnant woman${_ctx(body)} describes this symptom: "${symptom}". ` +
          'Respond with ONLY JSON: {"isCommon":boolean,"whatItMeans":string,' +
          '"urgency":"routine"|"call_soon"|"urgent","selfCare":[string],' +
          '"seekCareIf":[string],"disclaimer":string}. Set "urgency" to "urgent" for any ' +
          'red flag (heavy bleeding, severe or constant abdominal pain, severe headache ' +
          'with vision changes, no fetal movement, fluid leaking, high fever, fainting, ' +
          'thoughts of self-harm) and tell her to contact her doctor or emergency services ' +
          'now. Keep it warm and brief. JSON only.',
      };
    }
    case 'meal_plan': {
      const diet = _str(body.diet, 40) || 'vegetarian';
      return {
        system: _SAFE + ' Here you suggest a simple, balanced pregnancy meal plan.',
        maxTokens: 3072,
        instruction:
          `Create a 7-day India-first pregnancy meal plan${_ctx(body)}. Diet preference: ` +
          `${diet}. ${_conditions(body)} Respond with ONLY JSON: {"days":[{"day":string,` +
          '"breakfast":string,"lunch":string,"snack":string,"dinner":string}],' +
          '"keyNutrients":[string],"tips":[string],"disclaimer":string}. Exactly 7 days ' +
          '(Monday-Sunday), each meal one short line, affordable common Indian foods, ' +
          'respect the diet preference and any conditions (e.g., gestational diabetes -> ' +
          'low-glycemic, controlled portions). JSON only.',
      };
    }
    case 'wellness_plan': {
      return {
        system: _SAFE + ' Here you suggest safe, gentle yoga and light exercise for pregnancy.',
        maxTokens: 2560,
        instruction:
          `Suggest a safe pregnancy movement plan${_ctx(body)}. ${_conditions(body)} ` +
          'Respond with ONLY JSON: {"focus":string,"yoga":[{"name":string,"benefit":string,' +
          '"steps":[string],"caution":string}],"exercises":[{"name":string,"benefit":string,' +
          '"howTo":string,"minutes":number}],"healthTips":[string],"avoid":[string],' +
          '"disclaimer":string}. Include 3-4 gentle prenatal yoga poses (with simple steps) ' +
          'and 3-4 light exercises appropriate to the trimester and conditions. "healthTips" ' +
          'should be practical ways to improve wellbeing. "avoid" lists movements to skip. ' +
          'Never suggest anything strenuous or risky in pregnancy. JSON only.',
      };
    }
    case 'weekly_summary': {
      const stats = body.stats ? JSON.stringify(body.stats).slice(0, 2000) : '';
      if (!stats || stats === '{}') return { error: 'No data to summarise yet.' };
      return {
        system: _SAFE + ' Here you summarise her own logged health data for the week.',
        maxTokens: 1024,
        instruction:
          `Here is a pregnant woman's logged data for the past week${_ctx(body)} as JSON: ` +
          `${stats}. Write a warm, plain-language summary based ONLY on this data (do not ` +
          'invent values). Respond with ONLY JSON: {"summary":string,"highlights":[string],' +
          '"watchOuts":[string],"disclaimer":string}. "watchOuts" = gentle, non-alarming ' +
          'things worth mentioning to her doctor. JSON only.',
      };
    }
    case 'interactions': {
      const meds = Array.isArray(body.medicines)
        ? body.medicines.map((m) => _str(m, 80)).filter(Boolean).slice(0, 25)
        : [];
      if (meds.length === 0) return { error: 'Add some medicines first.' };
      return {
        system: _SAFE + ' Here you flag well-known medicine interactions and pregnancy cautions.',
        maxTokens: 1536,
        instruction:
          `A pregnant woman is taking these medicines: ${meds.join(', ')}. Identify only ` +
          'well-known, notable interactions between them or important pregnancy cautions. ' +
          'Respond with ONLY JSON: {"pairs":[{"a":string,"b":string,' +
          '"severity":"low"|"moderate"|"high","note":string}],"generalNotes":[string],' +
          '"disclaimer":string}. If nothing notable, return empty "pairs" and a reassuring ' +
          'general note. Always say to confirm with her doctor or pharmacist. JSON only.',
      };
    }
    case 'wellbeing': {
      const feeling = _str(body.feeling, 200);
      if (!feeling) return { error: 'Tell me how you are feeling.' };
      return {
        system: _SAFE +
          ' Here you gently suggest safe, uplifting ways for an expecting ' +
          'mother to cope with how she feels (calming activities, music, books, ' +
          'meditation/yoga). Be warm and practical. For low mood or possible ' +
          'depression, and for poor sleep, always also encourage her to talk to ' +
          'her doctor; if she hints at self-harm, urge her to seek immediate help.',
        maxTokens: 1200,
        instruction:
          `An expecting mother${_ctx(body)} is feeling: "${feeling}". ${_conditions(body)} ` +
          'Suggest gentle, safe, pregnancy-appropriate ways to feel better and ' +
          'divert her mind. Respond with ONLY JSON: {"supportive":string,' +
          '"activities":[string],"music":[string],"books":[{"title":string,' +
          '"author":string}],"meditationYoga":[string],"seekHelp":string,' +
          '"urgent":boolean,"disclaimer":string}. ' +
          '"supportive" = 1-2 warm, validating sentences. ' +
          '"music" = 2-4 YouTube SEARCH phrases for calming/uplifting music good ' +
          'in pregnancy (search terms, NOT specific video links). ' +
          '"books" = 2-3 real, well-known uplifting / self-care / pregnancy books ' +
          'with author. "activities" = simple diversions (a short walk, journaling, ' +
          'calling a friend, art, warm bath). "meditationYoga" = safe prenatal ' +
          'meditation / breathing / gentle yoga ideas; if she sleeps poorly include ' +
          'a wind-down bedtime routine. "seekHelp" = when to contact her doctor or ' +
          'a mental-health professional (for persistent low mood/depression, ' +
          'emphasise this warmly). Set "urgent" true ONLY for red flags such as ' +
          'thoughts of self-harm, and tell her to seek help immediately. ' +
          'India-first, kind and non-judgemental. JSON only.',
      };
    }
    case 'myth_of_day': {
      return {
        system: _SAFE +
          ' Here you surface ONE common pregnancy myth that is especially ' +
          'relevant to this mother’s current stage and situation, and explain ' +
          'it warmly and respectfully.',
        maxTokens: 1024,
        instruction:
          `Choose ONE common pregnancy myth that is especially relevant to a ` +
          `mother${_ctx(body)}. ${_conditions(body)} Prefer a myth that connects ` +
          'to her current trimester/stage (or her condition, if any is given). ' +
          'Respond with ONLY JSON: {"myth":string,"fact":string,"origin":string,' +
          '"takeaway":string,"disclaimer":string}. "myth" = the false belief in ' +
          'one sentence; "fact" = the evidence-based truth; "origin" = where the ' +
          'myth likely came from (cultural, historical, traditional or ' +
          'observational reasons), 1–2 sentences, respectful of tradition; ' +
          '"takeaway" = a gentle practical tip. India-first context. Keep each ' +
          'field short. JSON only.',
      };
    }
    case 'myth_explain': {
      const myth = _str(body.myth, 300);
      const fact = _str(body.fact, 400);
      if (!myth) return { error: 'No myth provided.' };
      return {
        system: _SAFE +
          ' Here you explain, warmly and without judgement, where a common ' +
          'pregnancy myth likely came from and what the evidence actually says.',
        maxTokens: 1024,
        instruction:
          `A common pregnancy myth is: "${myth}".` +
          (fact ? ` The accepted fact is: "${fact}".` : '') +
          ' For an expecting mother (India-first context), explain WHERE this ' +
          'myth likely originated — the cultural, historical, traditional or ' +
          'observational reasons people came to believe it — then give the ' +
          'evidence-based truth and a gentle, practical takeaway. Respect ' +
          'tradition; never mock it. Respond with ONLY JSON: ' +
          '{"origin":string,"truth":string,"takeaway":string,"disclaimer":string}. ' +
          'Keep each field to 1–3 short sentences. JSON only.',
      };
    }
    case 'baby_names': {
      const gender = _str(body.gender, 20) || 'any';
      const startsWith = _str(body.startsWith, 3);
      const origin = _str(body.origin, 60);
      const theme = _str(body.theme, 200);
      return {
        system:
          'You are a warm, knowledgeable baby-name expert for an India-first ' +
          'pregnancy app. You suggest real, well-known baby names (with a strong ' +
          'India-first lean, but open to any culture the parents ask for) and give ' +
          'accurate, concise meanings and origins.',
        maxTokens: 2048,
        instruction:
          'Suggest 12 baby names based on these parent preferences:\n' +
          `- Gender: ${gender} (boy, girl, unisex, or any)\n` +
          `- Starts with: ${startsWith || 'any letter'}\n` +
          `- Preferred origin/culture/religion: ${origin || 'any (India-first)'}\n` +
          `- Style / theme / meaning wanted: ${theme || 'any beautiful, modern, easy-to-pronounce name'}\n` +
          'Respond with ONLY JSON: {"suggestions":[{"name":string,' +
          '"gender":"boy"|"girl"|"unisex","origin":string,"meaning":string}],' +
          '"note":string}. Give 12 varied, genuine names that fit the preferences, ' +
          'each with a short accurate meaning and its origin. "note" is one friendly ' +
          'sentence. Never invent fake names or meanings. JSON only.',
      };
    }
    default:
      return { error: 'Unknown task.' };
  }
}

function _ctx(body) {
  const c = body.context || {};
  const bits = [];
  if (c.currentWeek != null) bits.push(`week ${c.currentWeek}`);
  if (c.trimester) bits.push(`${c.trimester}`);
  return bits.length ? ` (${bits.join(', ')})` : '';
}

function _conditions(body) {
  const c = body.context || {};
  const list = Array.isArray(c.conditions) ? c.conditions.filter(Boolean) : [];
  const risk = _str(c.risk, 40);
  const parts = [];
  if (list.length) parts.push(`Health conditions: ${list.join(', ')}.`);
  if (risk) parts.push(`Risk level: ${risk}.`);
  return parts.join(' ');
}

/// Strips a leading/trailing markdown code fence if the model added one.
function stripCodeFence(s) {
  const t = s.trim();
  if (t.startsWith('```')) {
    return t.replace(/^```[a-zA-Z]*\s*/, '').replace(/```$/, '').trim();
  }
  return t;
}

/// Parses JSON from the model, tolerating a truncated response (e.g. the output
/// hit the token cap mid-array). First tries a clean parse; if that fails, it
/// trims to the last complete object and closes any open [ and { brackets so a
/// long-but-cut-off prescription still yields the medicines read so far.
function parseJsonLenient(text) {
  const t = stripCodeFence(text);
  if (!t) return null;
  try {
    return JSON.parse(t);
  } catch (_) {}
  const lastBrace = t.lastIndexOf('}');
  if (lastBrace <= 0) return null;
  let c = t.slice(0, lastBrace + 1);
  const arrOpen = (c.match(/\[/g) || []).length - (c.match(/\]/g) || []).length;
  for (let i = 0; i < arrOpen; i++) c += ']';
  const objOpen = (c.match(/\{/g) || []).length - (c.match(/\}/g) || []).length;
  for (let i = 0; i < objOpen; i++) c += '}';
  try {
    return JSON.parse(c);
  } catch (_) {
    return null;
  }
}

// --------------------------- prompt building ---------------------------

/// Returns a directive telling the model which language to reply in. For the
/// JSON tasks, keeps the JSON keys in English and translates only the values.
/// Returns '' for English (the default), so behaviour is unchanged.
function _langDirective(lang, jsonMode = false) {
  if (typeof lang !== 'string' || lang.toLowerCase() !== 'hi') return '';
  const base =
    '\n\nIMPORTANT — LANGUAGE: Reply ENTIRELY in Hindi using Devanagari script. ' +
    'Every explanation, summary, note, tip, warning and disclaimer must be in ' +
    'natural, simple, warm Hindi. Medicine names and medical test names may stay ' +
    'in English or as written on the document.';
  const jsonNote = jsonMode
    ? ' Keep every JSON key exactly as specified in English; translate ONLY the ' +
      'human-readable string VALUES into Hindi. Fields whose values are fixed enums ' +
      '(like "urgency", "status", "severity", "timing", booleans and numbers) must ' +
      'keep their exact English enum value — do NOT translate those.'
    : '';
  return base + jsonNote;
}

/// Builds the system prompt, folding in the mother's pregnancy context.
function buildSystemPrompt(ctx = {}, lang) {
  ctx = ctx || {};
  const parts = [
    'You are "Mira", the caring AI companion inside the Pregnancy Companion app, ' +
      'an India-first pregnancy support app. You support expecting mothers and their ' +
      'families through pregnancy with warm, encouraging, practical guidance.',
    '',
    'Style:',
    '- Be warm, reassuring, and concise. Short paragraphs; use simple language.',
    '- Default to English; if the user writes in Hindi or Hinglish, reply in kind.',
    '- Prefer India-relevant examples (foods, customs, healthcare context) when helpful.',
    '',
    'Safety — this is not negotiable:',
    '- You are NOT a doctor and must never diagnose, prescribe, or give a treatment plan. ' +
      'Give general educational information and always encourage confirming with her ' +
      'obstetrician/gynaecologist or midwife.',
    '- If the message describes any RED-FLAG symptom — heavy bleeding, severe or ' +
      'persistent abdominal pain, severe headache with vision changes, no fetal ' +
      'movement, fluid leaking, high fever, fainting, thoughts of self-harm — respond ' +
      'briefly, urge her to contact her doctor or emergency services immediately, and ' +
      "mention the app's Emergency screen. Do not downplay it.",
    '- Do not give specific medication dosages. Refer medication questions to her doctor/pharmacist.',
    '- Stay on pregnancy, maternal health, newborn care, and closely related wellbeing topics. ' +
      'Politely redirect clearly unrelated requests.',
  ];

  const facts = [];
  if (ctx.name) facts.push(`Mother's name: ${ctx.name}`);
  if (ctx.currentWeek != null) facts.push(`Current pregnancy week: ${ctx.currentWeek} of 40`);
  if (ctx.trimester) facts.push(`Trimester: ${ctx.trimester}`);
  if (ctx.dueDate) facts.push(`Estimated due date: ${ctx.dueDate}`);
  if (facts.length) {
    parts.push('', 'What you know about this user:', ...facts.map((f) => `- ${f}`));
  }

  return parts.join('\n') + _langDirective(lang, false);
}

/// Normalizes and validates the client-supplied conversation.
function sanitizeMessages(raw) {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new Error('A non-empty "messages" array is required.');
  }
  const trimmed = raw.slice(-MAX_MESSAGES);
  const messages = trimmed
    .map((m) => {
      const role = m && m.role === 'assistant' ? 'assistant' : 'user';
      const content = typeof (m && m.content) === 'string' ? m.content.trim() : '';
      return { role, content: content.slice(0, MAX_CHARS) };
    })
    .filter((m) => m.content.length > 0);

  if (messages.length === 0) throw new Error('No valid message content provided.');
  // The conversation must start with a user turn.
  while (messages.length && messages[0].role !== 'user') messages.shift();
  if (messages.length === 0) throw new Error('Conversation must start with a user message.');
  return messages;
}

// --------------------------- Firebase ID token verification ---------------------------

const JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

let _jwksCache = { keys: null, exp: 0 };

/// Verifies a Firebase ID token (RS256) against Google's public keys and checks
/// the standard claims. Throws on any failure. Returns the decoded payload.
async function verifyFirebaseIdToken(token, projectId) {
  if (!projectId) throw new Error('Server missing FIREBASE_PROJECT_ID.');
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('Malformed token.');
  const [headerB64, payloadB64, sigB64] = parts;
  const header = JSON.parse(utf8(base64urlToBytes(headerB64)));
  const payload = JSON.parse(utf8(base64urlToBytes(payloadB64)));

  if (header.alg !== 'RS256') throw new Error('Unexpected alg.');

  const now = Math.floor(Date.now() / 1000);
  const skew = 60; // seconds of clock tolerance
  if (payload.aud !== projectId) throw new Error('Bad audience.');
  if (payload.iss !== `https://securetoken.google.com/${projectId}`) {
    throw new Error('Bad issuer.');
  }
  if (typeof payload.sub !== 'string' || payload.sub.length === 0) {
    throw new Error('Bad subject.');
  }
  if (typeof payload.exp !== 'number' || payload.exp < now - skew) throw new Error('Expired.');
  if (typeof payload.iat !== 'number' || payload.iat > now + skew) throw new Error('Issued in future.');

  const keys = await fetchJwks();
  const jwk = keys.find((k) => k.kid === header.kid);
  if (!jwk) throw new Error('Unknown signing key.');

  const key = await crypto.subtle.importKey(
    'jwk',
    { kty: jwk.kty, n: jwk.n, e: jwk.e, alg: 'RS256', ext: true },
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );

  const signed = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
  const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, base64urlToBytes(sigB64), signed);
  if (!ok) throw new Error('Bad signature.');
  return payload;
}

async function fetchJwks() {
  const now = Date.now();
  if (_jwksCache.keys && now < _jwksCache.exp) return _jwksCache.keys;
  const res = await fetch(JWKS_URL);
  if (!res.ok) throw new Error('Could not fetch signing keys.');
  const body = await res.json();
  const keys = body.keys || [];
  _jwksCache = { keys, exp: now + 3600 * 1000 }; // refresh hourly
  return keys;
}

// --------------------------- admin (service account) ---------------------------

let _saTokenCache = { token: null, exp: 0 };

/// Mints a Google OAuth access token for the Firebase service account
/// (env.FIREBASE_SA = the downloaded service-account JSON, set as a secret).
/// Used for privileged Admin operations (delete/disable a login account).
async function getSaAccessToken(env) {
  if (!env.FIREBASE_SA) throw new Error('admin-not-configured');
  const now = Math.floor(Date.now() / 1000);
  if (_saTokenCache.token && now < _saTokenCache.exp - 60) return _saTokenCache.token;

  const sa = JSON.parse(env.FIREBASE_SA);
  const enc = (o) => _b64url(new TextEncoder().encode(JSON.stringify(o)));
  const claim = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/cloud-platform',
    aud: sa.token_uri,
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${enc({ alg: 'RS256', typ: 'JWT' })}.${enc(claim)}`;
  const key = await _importPkcs8(sa.private_key);
  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${_b64url(new Uint8Array(sig))}`;

  const res = await fetch(sa.token_uri, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body:
      'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + jwt,
  });
  const data = await res.json();
  if (!data.access_token) throw new Error('sa-token-failed');
  _saTokenCache = { token: data.access_token, exp: now + (data.expires_in || 3600) };
  return data.access_token;
}

async function _importPkcs8(pem) {
  const b = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const bin = atob(b);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return crypto.subtle.importKey(
    'pkcs8',
    bytes.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

function _b64url(uint8) {
  let s = '';
  for (const byte of uint8) s += String.fromCharCode(byte);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/// The role stored on a user's Firestore doc (read with the SA token, which
/// bypasses security rules) — used to confirm the caller is really an admin.
async function _firestoreRole(pid, uid, saToken) {
  const r = await fetch(
    `https://firestore.googleapis.com/v1/projects/${pid}/databases/(default)/documents/users/${uid}`,
    { headers: { authorization: `Bearer ${saToken}` } },
  );
  if (!r.ok) return '';
  const d = await r.json();
  return (d.fields && d.fields.role && d.fields.role.stringValue) || '';
}

/// Deletes (best-effort) the pregnancies a user owns, so their data is removed
/// with the account. Tracker subcollections under a deleted pregnancy doc
/// become unreachable (rules require the parent doc), so they are effectively
/// gone even if not physically enumerated here.
async function _deleteOwnedPregnancies(pid, uid, saToken) {
  try {
    const q = {
      structuredQuery: {
        from: [{ collectionId: 'pregnancies' }],
        where: {
          fieldFilter: {
            field: { fieldPath: 'ownerUserId' },
            op: 'EQUAL',
            value: { stringValue: uid },
          },
        },
        limit: 50,
      },
    };
    const r = await fetch(
      `https://firestore.googleapis.com/v1/projects/${pid}/databases/(default)/documents:runQuery`,
      {
        method: 'POST',
        headers: { authorization: `Bearer ${saToken}`, 'content-type': 'application/json' },
        body: JSON.stringify(q),
      },
    );
    const rows = await r.json();
    for (const row of Array.isArray(rows) ? rows : []) {
      const name = row.document && row.document.name;
      if (name) {
        await fetch(`https://firestore.googleapis.com/v1/${name}`, {
          method: 'DELETE',
          headers: { authorization: `Bearer ${saToken}` },
        });
      }
    }
  } catch (_) {}
}

/// Admin-only: delete or disable a user's LOGIN account (+ their data on delete).
/// The caller must be an admin (verified via their Firestore user-doc role).
async function handleAdminUser(task, body, callerUid, env) {
  let saToken;
  try {
    saToken = await getSaAccessToken(env);
  } catch (_) {
    return json(
      { error: 'Admin actions are not set up on the server yet (missing service account).' },
      501,
    );
  }
  const pid = env.FIREBASE_PROJECT_ID;

  if ((await _firestoreRole(pid, callerUid, saToken)) !== 'admin') {
    return json({ error: 'Admins only.' }, 403);
  }
  const target = (body && typeof body.uid === 'string' && body.uid.trim()) || '';
  if (!target) return json({ error: 'Missing user id.' }, 400);
  if (target === callerUid) {
    return json({ error: "You can't delete or disable your own admin account here." }, 400);
  }

  const authBase = `https://identitytoolkit.googleapis.com/v1/projects/${pid}`;
  const hdr = { authorization: `Bearer ${saToken}`, 'content-type': 'application/json' };

  if (task === 'admin_disable_user') {
    const disabled = body.disabled !== false;
    const r = await fetch(`${authBase}/accounts:update`, {
      method: 'POST',
      headers: hdr,
      body: JSON.stringify({ localId: target, disableUser: disabled }),
    });
    if (!r.ok) return json({ error: 'Could not update the account.' }, 502);
    return json({ ok: true, disabled });
  }

  // admin_delete_user: remove the login account + their data.
  const del = await fetch(`${authBase}/accounts:delete`, {
    method: 'POST',
    headers: hdr,
    body: JSON.stringify({ localId: target }),
  });
  // (An already-deleted auth account is fine; continue to clean up data.)
  await fetch(
    `https://firestore.googleapis.com/v1/projects/${pid}/databases/(default)/documents/users/${target}`,
    { method: 'DELETE', headers: { authorization: `Bearer ${saToken}` } },
  );
  await _deleteOwnedPregnancies(pid, target, saToken);
  if (!del.ok && del.status !== 200) {
    // Data was removed but the auth delete failed — report partial.
    return json({ ok: true, authDeleted: false });
  }
  return json({ ok: true, authDeleted: true });
}

// --------------------------- small helpers ---------------------------

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json', ...corsHeaders() },
  });
}

function base64urlToBytes(s) {
  s = s.replace(/-/g, '+').replace(/_/g, '/');
  const pad = s.length % 4;
  if (pad) s += '='.repeat(4 - pad);
  const bin = atob(s);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

function utf8(bytes) {
  return new TextDecoder().decode(bytes);
}
