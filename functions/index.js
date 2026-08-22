/**
 * Cloud Functions for Pregnancy Companion.
 *
 * `aiAssistant` is a callable function that proxies the Claude API. The API key
 * lives server-side only (a Secret Manager secret) and never ships in the app.
 * The client sends the running conversation plus lightweight pregnancy context;
 * the function builds a safety-first system prompt and returns Claude's reply.
 */
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { setGlobalOptions } from 'firebase-functions/v2';
import Anthropic from '@anthropic-ai/sdk';

setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

const anthropicApiKey = defineSecret('ANTHROPIC_API_KEY');

// Configurable via env; Opus 5 by default. Set MODEL=claude-sonnet-5 to trade a
// little quality for lower cost/latency on high-volume traffic.
const MODEL = process.env.MODEL || 'claude-opus-5';

const MAX_MESSAGES = 20; // cap conversation history sent upstream
const MAX_CHARS = 4000; // cap per-message length

/// Builds the system prompt, folding in the mother's pregnancy context.
function buildSystemPrompt(ctx = {}) {
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
      'mention the app\'s Emergency screen. Do not downplay it.',
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

  return parts.join('\n');
}

/// Normalizes and validates the client-supplied conversation.
function sanitizeMessages(raw) {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new HttpsError('invalid-argument', 'A non-empty "messages" array is required.');
  }
  const trimmed = raw.slice(-MAX_MESSAGES);
  const messages = trimmed
    .map((m) => {
      const role = m && m.role === 'assistant' ? 'assistant' : 'user';
      const content = typeof (m && m.content) === 'string' ? m.content.trim() : '';
      return { role, content: content.slice(0, MAX_CHARS) };
    })
    .filter((m) => m.content.length > 0);

  if (messages.length === 0) {
    throw new HttpsError('invalid-argument', 'No valid message content provided.');
  }
  // The Messages API requires the first turn to be from the user.
  while (messages.length && messages[0].role !== 'user') messages.shift();
  if (messages.length === 0) {
    throw new HttpsError('invalid-argument', 'Conversation must start with a user message.');
  }
  return messages;
}

export const aiAssistant = onCall(
  { secrets: [anthropicApiKey], timeoutSeconds: 60, memory: '256MiB' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Sign in to use the assistant.');
    }

    const messages = sanitizeMessages(request.data && request.data.messages);
    const system = buildSystemPrompt(request.data && request.data.context);

    const client = new Anthropic({ apiKey: anthropicApiKey.value() });

    try {
      const response = await client.messages.create({
        model: MODEL,
        max_tokens: 1024,
        // Low effort keeps replies snappy for a conversational assistant.
        output_config: { effort: 'low' },
        system,
        messages,
      });

      if (response.stop_reason === 'refusal') {
        return {
          reply:
            "I'm sorry, I can't help with that. If this is about your health, " +
            'please reach out to your doctor.',
          model: response.model,
          refused: true,
        };
      }

      const reply = response.content
        .filter((b) => b.type === 'text')
        .map((b) => b.text)
        .join('\n')
        .trim();

      return {
        reply: reply || "I'm not sure how to answer that — could you rephrase?",
        model: response.model,
      };
    } catch (err) {
      console.error('aiAssistant Claude call failed', err);
      throw new HttpsError('internal', 'The assistant is unavailable right now. Please try again.');
    }
  },
);
