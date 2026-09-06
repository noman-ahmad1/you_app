const fs = require('fs');
const {
  initializeTestEnvironment, assertFails, assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc,
  collection, getDocs, query, where,
} = require('firebase/firestore');

let env;

// Actors
const ALICE = 'alice';   // ordinary user
const BOB   = 'bob';     // a different ordinary user (the attacker)
const VERA  = 'vera';    // volunteer
const ADMIN = 'admin';

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'you-app-test',
    firestore: {
      rules: fs.readFileSync('../firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => { if (env) await env.cleanup(); });

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', ALICE), { uid: ALICE, role: 'user', email: 'alice@x.com', phoneNumber: '+92300', status: 'active', fcmToken: 'tok-alice' });
    await setDoc(doc(db, 'users', BOB),   { uid: BOB,   role: 'user', email: 'bob@x.com', status: 'active' });
    await setDoc(doc(db, 'users', VERA),  { uid: VERA,  role: 'volunteer', email: 'vera@x.com', status: 'active', availabilityStatus: 'online' });
    await setDoc(doc(db, 'users', ADMIN), { uid: ADMIN, role: 'admin', email: 'admin@x.com', status: 'active' });

    await setDoc(doc(db, 'mood', 'm1'), { userId: ALICE, mood: 'low', extraField: 'private note' });

    await setDoc(doc(db, 'volunteer_info', VERA), {
      uid: VERA, tags: ['Anxiety'], institutionName: 'Uni',
      averageRating: 4.0, totalReviews: 10, completedChats: 5,
    });
    await setDoc(doc(db, 'volunteer_info', VERA, 'private', 'vetting'), {
      idCardUrl: 'https://firebasestorage/idcard?token=secret',
      studentIdUrl: 'https://firebasestorage/studentid?token=secret',
    });

    await setDoc(doc(db, 'chats', 'c1'), { participants: [ALICE, VERA], status: 'active', escalated: true });
    await setDoc(doc(db, 'chats', 'c1', 'messages', 'msg1'), { senderId: ALICE, text: 'I need help' });

    await setDoc(doc(db, 'communities', 'com1'), { name: 'Anxiety', membersCount: 10 });

    await setDoc(doc(db, 'chat_requests', 'r1'), {
      requesterId: ALICE, volunteerId: VERA, status: 'accepted',
    });
  });
});

// ---------------------------------------------------------------------------
describe('§4.2  mood is private health data', () => {
  it('the owner reads their own mood entry', async () => {
    await assertSucceeds(getDoc(doc(as(ALICE), 'mood', 'm1')));
  });
  it('another signed-in user CANNOT read it', async () => {
    await assertFails(getDoc(doc(as(BOB), 'mood', 'm1')));
  });
  it('another user CANNOT dump the whole mood collection', async () => {
    await assertFails(getDocs(collection(as(BOB), 'mood')));
  });
  it('the owner may still query their own entries', async () => {
    await assertSucceeds(getDocs(query(collection(as(ALICE), 'mood'), where('userId', '==', ALICE))));
  });
});

describe('§4.3  push-notification injection', () => {
  it('a user creates a notification for THEMSELVES', async () => {
    await assertSucceeds(addDoc(collection(as(ALICE), 'users', ALICE, 'notifications'), { title: 'hi', body: 'x', senderId: ALICE }));
  });
  it('a user CANNOT inject one into someone else\'s inbox', async () => {
    await assertFails(addDoc(collection(as(BOB), 'users', ALICE, 'notifications'), { title: 'spam', body: 'phish', senderId: BOB }));
  });
});

describe('§4.4  the user directory is not dumpable', () => {
  it('a user reads their own doc', async () => {
    await assertSucceeds(getDoc(doc(as(ALICE), 'users', ALICE)));
  });
  it('a user CANNOT read another user\'s doc directly', async () => {
    await assertFails(getDoc(doc(as(BOB), 'users', ALICE)));
  });
  it('a user CANNOT list the entire users collection', async () => {
    await assertFails(getDocs(collection(as(BOB), 'users')));
  });
  it('volunteer discovery still works (constrained query)', async () => {
    await assertSucceeds(getDocs(query(
      collection(as(ALICE), 'users'),
      where('role', '==', 'volunteer'),
      where('status', '==', 'active'),
      where('availabilityStatus', '==', 'online'),
    )));
  });
});

describe('§4.1  volunteer vetting documents', () => {
  it('public volunteer info stays readable (discovery UI)', async () => {
    await assertSucceeds(getDoc(doc(as(ALICE), 'volunteer_info', VERA)));
  });
  it('another user CANNOT read the vetting subdocument', async () => {
    await assertFails(getDoc(doc(as(BOB), 'volunteer_info', VERA, 'private', 'vetting')));
  });
  it('the volunteer reads their own vetting docs', async () => {
    await assertSucceeds(getDoc(doc(as(VERA), 'volunteer_info', VERA, 'private', 'vetting')));
  });
  it('an admin reads them for review', async () => {
    await assertSucceeds(getDoc(doc(as(ADMIN), 'volunteer_info', VERA, 'private', 'vetting')));
  });
});

describe('§4.6  aggregates are not client-writable', () => {
  it('a stranger CANNOT inflate a volunteer rating', async () => {
    await assertFails(updateDoc(doc(as(BOB), 'volunteer_info', VERA), { averageRating: 5, totalReviews: 9999 }));
  });
  it('a stranger CANNOT set an arbitrary membersCount', async () => {
    await assertFails(updateDoc(doc(as(BOB), 'communities', 'com1'), { membersCount: 999999 }));
  });
  it('joining a community (+1) is still allowed', async () => {
    await assertSucceeds(updateDoc(doc(as(BOB), 'communities', 'com1'), { membersCount: 11 }));
  });
  it('leaving a community (-1) is still allowed', async () => {
    await assertSucceeds(updateDoc(doc(as(BOB), 'communities', 'com1'), { membersCount: 9 }));
  });
});

describe('§4.5  chat integrity', () => {
  it('a participant sends a message', async () => {
    await assertSucceeds(addDoc(collection(as(ALICE), 'chats', 'c1', 'messages'), { senderId: ALICE, text: 'hello' }));
  });
  it('a non-participant cannot read the transcript', async () => {
    await assertFails(getDoc(doc(as(BOB), 'chats', 'c1', 'messages', 'msg1')));
  });
  it('a participant CANNOT edit a message (escalation evidence)', async () => {
    await assertFails(updateDoc(doc(as(VERA), 'chats', 'c1', 'messages', 'msg1'), { text: 'redacted' }));
  });
  it('a participant CANNOT delete a message', async () => {
    await assertFails(deleteDoc(doc(as(VERA), 'chats', 'c1', 'messages', 'msg1')));
  });
  it('a participant CANNOT add a third party to the chat', async () => {
    await assertFails(updateDoc(doc(as(ALICE), 'chats', 'c1'), { participants: [ALICE, VERA, BOB] }));
  });
  it('a participant CANNOT clear the escalation flag', async () => {
    await assertFails(updateDoc(doc(as(ALICE), 'chats', 'c1'), { escalated: false }));
  });
  it('a participant CANNOT delete an escalated chat', async () => {
    await assertFails(deleteDoc(doc(as(ALICE), 'chats', 'c1')));
  });
  it('a participant may still end the chat normally', async () => {
    await assertSucceeds(updateDoc(doc(as(ALICE), 'chats', 'c1'), { status: 'completed' }));
  });
});

describe('escalations cannot be spoofed', () => {
  it('a user raises an escalation about themselves', async () => {
    await assertSucceeds(addDoc(collection(as(ALICE), 'escalations'), {
      type: 'moderation', userId: ALICE, userName: 'Alice', reason: 'x', severity: 'high', status: 'open',
    }));
  });
  it('a user CANNOT fabricate one naming someone else', async () => {
    await assertFails(addDoc(collection(as(BOB), 'escalations'), {
      type: 'moderation', userId: ALICE, userName: 'Alice', reason: 'fake', severity: 'critical', status: 'open',
    }));
  });
  it('nobody can read the crisis feed except admins', async () => {
    await assertFails(getDocs(collection(as(BOB), 'escalations')));
    await assertSucceeds(getDocs(collection(as(ADMIN), 'escalations')));
  });
});

describe('privilege escalation stays closed (regression guard)', () => {
  it('a user cannot make themselves an admin', async () => {
    await assertFails(updateDoc(doc(as(ALICE), 'users', ALICE), { role: 'admin' }));
  });
  it('a user cannot grant themselves premium', async () => {
    await assertFails(updateDoc(doc(as(ALICE), 'users', ALICE), { subscriptionTier: 'premium' }));
  });
  it('a user can still edit their own profile', async () => {
    await assertSucceeds(updateDoc(doc(as(ALICE), 'users', ALICE), { firstName: 'Alicia' }));
  });
  it('anonymous users are locked out', async () => {
    await assertFails(getDoc(doc(anon(), 'users', ALICE)));
  });
});

// ---------------------------------------------------------------------------
// Regression guards for the LEGITIMATE client writes these rules must not break.
// Each mirrors a real call site in lib/.
describe('client flows still work after the lockdown', () => {
  it('chat_service notifies the other participant of a new message', async () => {
    // lib/services/chat_service.dart:274
    await assertSucceeds(addDoc(collection(as(VERA), 'users', ALICE, 'notifications'), {
      title: 'New Message', body: 'hi', type: 'new_message', isRead: false,
      data: { chatId: 'c1', route: 'chat_view' },
    }));
  });

  it('chat_request_service notifies the requester on accept', async () => {
    // lib/services/chat_request_service.dart:105
    await assertSucceeds(addDoc(collection(as(VERA), 'users', ALICE, 'notifications'), {
      title: 'Chat Request Accepted!', body: 'x', type: 'request_accepted', isRead: false,
      data: { requestId: 'r1', route: 'chat_view' },
    }));
  });

  it('a stranger with no shared chat/request is still refused', async () => {
    await assertFails(addDoc(collection(as(BOB), 'users', ALICE, 'notifications'), {
      title: 'spam', body: 'x', data: { chatId: 'c1' },
    }));
  });

  it('the review transaction bumps a volunteer aggregate by one', async () => {
    // lib/services/volunteer_service.dart:117 — averageRating recomputed,
    // totalReviews and completedChats each +1.
    await assertSucceeds(updateDoc(doc(as(ALICE), 'volunteer_info', VERA), {
      averageRating: 4.09, totalReviews: 11, completedChats: 6,
    }));
  });

  it('a user may still leave a review', async () => {
    await assertSucceeds(addDoc(collection(as(ALICE), 'volunteer_info', VERA, 'reviews'), {
      userId: ALICE, rating: 5, comment: 'helpful',
    }));
  });

  it('escalation_service marks a chat escalated (false -> true)', async () => {
    // lib/services/escalation_service.dart:84
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'chats', 'c2'),
        { participants: [ALICE, VERA], status: 'active', escalated: false });
    });
    await assertSucceeds(setDoc(doc(as(VERA), 'chats', 'c2'),
      { escalated: true, escalatedAt: new Date() }, { merge: true }));
  });

  it('a volunteer raises an escalation naming the user', async () => {
    // lib/services/escalation_service.dart:27 — volunteerId is the caller.
    await assertSucceeds(addDoc(collection(as(VERA), 'escalations'), {
      type: 'volunteer', chatId: 'c1', userId: ALICE, userName: 'Alice',
      volunteerId: VERA, volunteerName: 'Vera', severity: 'critical', status: 'open',
    }));
  });

  it('a non-escalated chat can still be deleted by a participant', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'chats', 'c3'),
        { participants: [ALICE, VERA], status: 'completed' });
    });
    await assertSucceeds(deleteDoc(doc(as(ALICE), 'chats', 'c3')));
  });

  it('participantsActivity updates are unaffected', async () => {
    // lib/services/chat_service.dart — setUserActiveInChat
    await assertSucceeds(setDoc(doc(as(ALICE), 'chats', 'c1'),
      { participantsActivity: { [ALICE]: true } }, { merge: true }));
  });
});

// ---------------------------------------------------------------------------
// The admin panel is a separate web app authenticating as a role:'admin' user.
// These pin the reads and writes it depends on, so a future rules change can't
// break it silently.
describe('admin panel access', () => {
  it('an admin can list the whole users collection', async () => {
    await assertSucceeds(getDocs(collection(as(ADMIN), 'users')));
  });
  it('an admin can read any user doc', async () => {
    await assertSucceeds(getDoc(doc(as(ADMIN), 'users', ALICE)));
  });
  it('an admin can read mood entries for the dashboard', async () => {
    await assertSucceeds(getDocs(collection(as(ADMIN), 'mood')));
  });
  it('an admin can read vetting documents', async () => {
    await assertSucceeds(getDoc(doc(as(ADMIN), 'volunteer_info', VERA, 'private', 'vetting')));
  });
  it('an admin can read a chat transcript for escalation review', async () => {
    await assertSucceeds(getDoc(doc(as(ADMIN), 'chats', 'c1', 'messages', 'msg1')));
  });
  it('an admin still CANNOT rewrite message content', async () => {
    await assertFails(updateDoc(doc(as(ADMIN), 'chats', 'c1', 'messages', 'msg1'), { text: 'edited' }));
  });
  it('an admin can end a chat', async () => {
    await assertSucceeds(updateDoc(doc(as(ADMIN), 'chats', 'c1'), { status: 'completed', endedBy: 'admin' }));
  });
  it('an admin can triage the escalation feed', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'escalations', 'e1'), { userId: ALICE, status: 'open' });
    });
    await assertSucceeds(updateDoc(doc(as(ADMIN), 'escalations', 'e1'), { status: 'acknowledged' }));
  });
  it('an admin can author a whisper; a user can only read it', async () => {
    await assertSucceeds(setDoc(doc(as(ADMIN), 'whispers', '2026-09-06'), { text: 'Be gentle with yourself.', active: true }));
    await assertSucceeds(getDoc(doc(as(ALICE), 'whispers', '2026-09-06')));
    await assertFails(setDoc(doc(as(ALICE), 'whispers', '2026-09-06'), { text: 'nope', active: true }));
  });
  it('an admin can moderate a volunteer profile', async () => {
    await assertSucceeds(updateDoc(doc(as(ADMIN), 'volunteer_info', VERA), { status: 'verified' }));
  });
});
