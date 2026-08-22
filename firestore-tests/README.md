# Firestore rules unit tests

Security-rules unit tests for [`../firestore.rules`](../firestore.rules). They run
against the Firestore emulator with mock signed-in users — no Android emulator,
login, or UI needed — and pin the pre-launch hardening:

- `role` / `isPremium` can't be self-granted by the client
- pregnancy tracker data is member-scoped (journal is owner-only)
- the community feed can't be tampered with (no fabricated likes/comment counts)

## Run

One-time setup:

```sh
cd firestore-tests && npm install
```

Then, from the **project root** (needs Java on PATH for the emulator — the
Android Studio JBR works):

```sh
# bash
export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"
firebase emulators:exec --only firestore --project demo-pregnancy \
  "node --test firestore-tests/rules.test.mjs"
```

Green run ends with `pass 19  fail 0` and `Script exited successfully`.

## When to run

Re-run after **any** edit to `firestore.rules`, and before deploying
(`firebase deploy --only firestore:rules`). Add a case here whenever you add or
change a rule.
