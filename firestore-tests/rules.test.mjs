// Security-rules unit tests for ../firestore.rules.
//
// These exercise the deployed rules logic against the Firestore emulator with
// mock authenticated users — no Android emulator, login, or UI needed. Run via:
//   firebase emulators:exec --only firestore --project demo-pregnancy "node --test firestore-tests"
//
// They pin the pre-launch hardening: role/premium can't be self-granted,
// tracker data is member-scoped, and the community feed can't be tampered with.

import { readFileSync } from 'node:fs';
import { before, after, beforeEach, test } from 'node:test';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-pregnancy',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

// A Firestore handle acting as the given signed-in user (optional token claims).
const as = (uid, claims = {}) => testEnv.authenticatedContext(uid, claims).firestore();

// Seed documents with rules bypassed (admin-style setup).
const seed = (fn) =>
  testEnv.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

const goodPost = (author) => ({
  authorUid: author,
  authorName: 'A mom',
  text: 'hello world',
  createdAt: '2026-01-01T00:00:00Z',
  likedBy: [],
  commentCount: 0,
});

// ---------------- users: role & premium are server-authoritative ----------------

test('user may create own doc as mother (non-premium)', async () => {
  const db = as('alice');
  await assertSucceeds(
    setDoc(doc(db, 'users/alice'), { uid: 'alice', role: 'mother', isPremium: false }),
  );
});

test('user CANNOT self-assign the doctor role', async () => {
  const db = as('alice');
  await assertFails(
    setDoc(doc(db, 'users/alice'), { uid: 'alice', role: 'doctor', isPremium: false }),
  );
});

test('user CANNOT self-assign the admin role', async () => {
  const db = as('alice');
  await assertFails(
    setDoc(doc(db, 'users/alice'), { uid: 'alice', role: 'admin', isPremium: false }),
  );
});

test('user CANNOT grant itself premium on create', async () => {
  const db = as('alice');
  await assertFails(
    setDoc(doc(db, 'users/alice'), { uid: 'alice', role: 'mother', isPremium: true }),
  );
});

test('user CANNOT flip premium on update', async () => {
  await seed((db) => setDoc(doc(db, 'users/alice'), { uid: 'alice', role: 'mother', isPremium: false }));
  const db = as('alice');
  await assertFails(updateDoc(doc(db, 'users/alice'), { isPremium: true }));
});

test('a provisioned doctor keeps their role on an unrelated update', async () => {
  await seed((db) => setDoc(doc(db, 'users/doc1'), { uid: 'doc1', role: 'doctor', isPremium: false }));
  const db = as('doc1');
  await assertSucceeds(updateDoc(doc(db, 'users/doc1'), { displayName: 'Dr. Rao' }));
});

test('a doctor CANNOT self-elevate to admin', async () => {
  await seed((db) => setDoc(doc(db, 'users/doc1'), { uid: 'doc1', role: 'doctor', isPremium: false }));
  const db = as('doc1');
  await assertFails(updateDoc(doc(db, 'users/doc1'), { role: 'admin' }));
});

test('a user CANNOT read another user document', async () => {
  await seed((db) => setDoc(doc(db, 'users/bob'), { uid: 'bob', role: 'mother' }));
  const db = as('alice');
  await assertFails(getDoc(doc(db, 'users/bob')));
});

// ---------------- pregnancy tracker data is member-scoped ----------------

test('a member can read tracker data; a non-member cannot', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'pregnancies/p1'), {
      ownerUserId: 'alice',
      members: { alice: { role: 'mother' } },
    });
    await setDoc(doc(db, 'pregnancies/p1/medicines/m1'), { name: 'Iron' });
  });
  await assertSucceeds(getDoc(doc(as('alice'), 'pregnancies/p1/medicines/m1')));
  await assertFails(getDoc(doc(as('bob'), 'pregnancies/p1/medicines/m1')));
});

test('members only read categories the owner has shared', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'pregnancies/p3'), {
      ownerUserId: 'alice',
      members: { alice: {}, bob: {} },
      // appointments shared by default; vitals explicitly off.
      sharing: { vitals: false, appointments: true },
    });
    await setDoc(doc(db, 'pregnancies/p3/weight/w1'), { kg: 60 });
    await setDoc(doc(db, 'pregnancies/p3/appointments/a1'), { title: 'Scan' });
  });
  // bob is a member but vitals are not shared -> denied.
  await assertFails(getDoc(doc(as('bob'), 'pregnancies/p3/weight/w1')));
  // appointments are shared -> allowed.
  await assertSucceeds(getDoc(doc(as('bob'), 'pregnancies/p3/appointments/a1')));
  // the owner reads regardless of sharing.
  await assertSucceeds(getDoc(doc(as('alice'), 'pregnancies/p3/weight/w1')));
});

test('emergency contacts are member-readable, owner-writable', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'pregnancies/p4'), {
      ownerUserId: 'alice',
      members: { alice: {}, bob: {} },
    });
    await setDoc(doc(db, 'pregnancies/p4/emergency_contacts/c1'),
        { name: 'Dad', phone: '123' });
  });
  await assertSucceeds(getDoc(doc(as('bob'), 'pregnancies/p4/emergency_contacts/c1')));
  await assertFails(
    setDoc(doc(as('bob'), 'pregnancies/p4/emergency_contacts/c2'), { name: 'x' }));
  await assertSucceeds(
    setDoc(doc(as('alice'), 'pregnancies/p4/emergency_contacts/c2'), { name: 'Mom' }));
});

test('any member may raise an SOS for themselves', async () => {
  await seed((db) => setDoc(doc(db, 'pregnancies/p5'),
      { ownerUserId: 'alice', members: { alice: {}, bob: {} } }));
  await assertSucceeds(setDoc(doc(as('bob'), 'pregnancies/p5/sos_alerts/s1'),
      { createdBy: 'bob', status: 'active' }));
  await assertFails(setDoc(doc(as('bob'), 'pregnancies/p5/sos_alerts/s2'),
      { createdBy: 'alice', status: 'active' })); // can't forge another uid
});

test('the owner can read tracker data even if absent from members', async () => {
  // Data-drift guard: a pregnancy whose members map somehow omits the owner.
  await seed(async (db) => {
    await setDoc(doc(db, 'pregnancies/p2'), {
      ownerUserId: 'carol',
      members: {},
    });
    await setDoc(doc(db, 'pregnancies/p2/medicines/m1'), { name: 'Calcium' });
  });
  await assertSucceeds(getDoc(doc(as('carol'), 'pregnancies/p2/medicines/m1')));
  await assertFails(getDoc(doc(as('bob'), 'pregnancies/p2/medicines/m1')));
});

test('the pregnancy doc itself is readable by any signed-in user (invite-code model)', async () => {
  await seed((db) => setDoc(doc(db, 'pregnancies/p1'), { ownerUserId: 'alice', members: { alice: {} } }));
  await assertSucceeds(getDoc(doc(as('bob'), 'pregnancies/p1')));
});

test('the private journal is owner-only, even for members', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'pregnancies/p1'), {
      ownerUserId: 'alice',
      members: { alice: {}, bob: {} },
    });
    await setDoc(doc(db, 'pregnancies/p1/journal/j1'), { text: 'private' });
  });
  await assertSucceeds(getDoc(doc(as('alice'), 'pregnancies/p1/journal/j1')));
  await assertFails(getDoc(doc(as('bob'), 'pregnancies/p1/journal/j1'))); // bob is a member but not owner
});

// ---------------- community feed integrity ----------------

test('a valid post create succeeds', async () => {
  await assertSucceeds(setDoc(doc(as('alice'), 'community_posts/post1'), goodPost('alice')));
});

test('CANNOT create a post authored by someone else', async () => {
  await assertFails(setDoc(doc(as('alice'), 'community_posts/post1'), goodPost('bob')));
});

test('CANNOT create a post with pre-set likes', async () => {
  await assertFails(
    setDoc(doc(as('alice'), 'community_posts/post1'), { ...goodPost('alice'), likedBy: ['x'] }),
  );
});

test('CANNOT create a post with a nonzero comment count', async () => {
  await assertFails(
    setDoc(doc(as('alice'), 'community_posts/post1'), { ...goodPost('alice'), commentCount: 9 }),
  );
});

test('CANNOT create a post with empty text', async () => {
  await assertFails(
    setDoc(doc(as('alice'), 'community_posts/post1'), { ...goodPost('alice'), text: '' }),
  );
});

test('a user can like a post by adding their own uid', async () => {
  await seed((db) => setDoc(doc(db, 'community_posts/post1'), goodPost('bob')));
  await assertSucceeds(updateDoc(doc(as('alice'), 'community_posts/post1'), { likedBy: ['alice'] }));
});

test('a user CANNOT inflate the comment count arbitrarily', async () => {
  await seed((db) => setDoc(doc(db, 'community_posts/post1'), goodPost('bob')));
  await assertFails(updateDoc(doc(as('alice'), 'community_posts/post1'), { commentCount: 100 }));
});

test('the comment count may be bumped by exactly one', async () => {
  await seed((db) => setDoc(doc(db, 'community_posts/post1'), goodPost('bob')));
  await assertSucceeds(updateDoc(doc(as('alice'), 'community_posts/post1'), { commentCount: 1 }));
});
