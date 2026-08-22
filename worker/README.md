# Ask Mira — AI proxy (Cloudflare Worker, free)

A tiny serverless endpoint that answers the app's "Ask Mira" chats. It runs on
**Cloudflare Workers' free tier** and uses **Google Gemini's free API tier**, so
the whole feature costs nothing at low volume:

- Hosting: Cloudflare Workers — free
- Backend: Firebase stays on the free **Spark** plan
- AI: Google Gemini free tier (Google AI Studio) — free (with daily limits)

**What it does** — verifies the caller's Firebase ID token (only signed-in app
users can call it), builds a safety-first system prompt, proxies the Gemini
`generateContent` API, and returns `{ reply, model, refused? }`. The Gemini key
lives on this server only, never in the app.

---

## One-time deploy

You need a free Cloudflare account and a free Gemini API key.

1. **Get a free Gemini API key**
   - Go to https://aistudio.google.com/app/apikey (sign in with a Google account)
   - Click **Create API key** → copy it. It's free; no card required.

2. **Install deps** (from this `worker/` folder):
   ```sh
   cd worker
   npm install
   ```

3. **Log in to Cloudflare** (opens a browser — click Allow):
   ```sh
   npx wrangler login
   ```

4. **Set the Gemini key as a secret** (never goes in any file):
   ```sh
   npx wrangler secret put GEMINI_API_KEY
   ```
   Paste your key when prompted (input is hidden — that's normal).

5. **Deploy:**
   ```sh
   npx wrangler deploy
   ```
   Wrangler prints the public URL, e.g.
   `https://pregnancy-ai.<your-subdomain>.workers.dev`. **Copy it.**

6. **Point the app at it.** Either:
   - Edit `lib/core/config/app_config.dart` → replace the `REPLACE_ME`
     placeholder in `_aiEndpoint` with your Worker URL, **or**
   - Build with `flutter run --dart-define=AI_ENDPOINT=https://pregnancy-ai.<your-subdomain>.workers.dev`

`FIREBASE_PROJECT_ID` is already set in `wrangler.toml` (must match the app's
Firebase project so token verification works).

## Test it quickly

```sh
curl -X POST https://pregnancy-ai.<your-subdomain>.workers.dev \
  -H "Authorization: Bearer <a-firebase-id-token>" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Is papaya safe in pregnancy?"}],"context":{"currentWeek":20}}'
```

A request with no/invalid token returns `401` — that's the abuse guard working.

## Notes

- **Model:** defaults to `gemini-2.0-flash` (a free-tier model). If that model
  ever errors, set `MODEL` in `wrangler.toml` to another free option like
  `gemini-2.5-flash` or `gemini-1.5-flash`, then redeploy.
- **Free-tier limits:** Gemini's free tier has per-minute and per-day request
  caps. Fine for a small app; if you outgrow them, either enable Gemini billing
  or switch the proxy to another provider.
- **Local dev:** `npx wrangler dev` runs it at `http://localhost:8787` (set the
  secret first, or use a `.dev.vars` file — do not commit it).
- The old Firebase function in `../functions/` is superseded and unused (it
  required the paid Blaze plan). Keep for reference or delete.
