// All Firestore reads and writes for a meeting.
//
// Every subscribe* function returns an unsubscribe function and reports data
// through a callback, so the caller decides what to do with it. That is what
// keeps this module free of any store import, and it is what makes the live
// updates work: two browsers running the app both receive the same snapshot.
import {
    addDoc, arrayUnion, collection, deleteDoc, doc, getDocs,
    limit, onSnapshot, orderBy, query, serverTimestamp, setDoc, updateDoc, where,
} from "firebase/firestore";
import { db, MEETUPS } from "./firebase.js";
import { plainify } from "./plainify.js";

function meetupDoc(meetupId) {
    return doc(db, MEETUPS, meetupId);
}

function subDoc(meetupId, sub, uid) {
    return doc(db, MEETUPS, meetupId, sub, uid);
}

function subCollection(meetupId, sub) {
    return collection(db, MEETUPS, meetupId, sub);
}

function keyById(snapshot) {
    const result = {};
    snapshot.forEach(function eachACB(document) {
        result[document.id] = plainify({ uid: document.id, id: document.id, ...document.data() });
    });
    return result;
}

export function makeInviteCode() {
    const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    let code = "";
    for (let i = 0; i < 6; i += 1) {
        code += alphabet[Math.floor(Math.random() * alphabet.length)];
    }
    return `${code.slice(0, 3)}-${code.slice(3)}`;
}

export function createMeetup(meetup) {
    return addDoc(collection(db, MEETUPS), {
        ...meetup,
        createdAt: serverTimestamp(),
    }).then(function createdACB(reference) {
        return reference.id;
    });
}

export function updateMeetup(meetupId, changes) {
    return updateDoc(meetupDoc(meetupId), changes);
}

export function findMeetupByInviteCode(code) {
    const matching = query(
        collection(db, MEETUPS),
        where("inviteCode", "==", code.trim().toUpperCase()),
        limit(1),
    );
    return getDocs(matching).then(function foundACB(snapshot) {
        if (snapshot.empty) {
            throw new Error(`No Catch Up found for the code ${code}`);
        }
        const document = snapshot.docs[0];
        return plainify({ id: document.id, ...document.data() });
    });
}

export function joinMeetup(meetupId, uid) {
    return updateDoc(meetupDoc(meetupId), { memberIds: arrayUnion(uid) });
}

// --- per-user documents: a member may only write their own ---

export function writeParticipant(meetupId, uid, participant) {
    return setDoc(subDoc(meetupId, "participants", uid), {
        ...participant,
        updatedAt: serverTimestamp(),
    }, { merge: true });
}

export function writeAvailability(meetupId, uid, intervals) {
    return setDoc(subDoc(meetupId, "availability", uid), {
        intervals,
        updatedAt: serverTimestamp(),
    });
}

export function writeVote(meetupId, uid, optionIds) {
    return setDoc(subDoc(meetupId, "votes", uid), {
        optionIds,
        updatedAt: serverTimestamp(),
    });
}

// --- shared candidate options ---

export function writeOption(meetupId, optionId, option) {
    return setDoc(doc(db, MEETUPS, meetupId, "options", optionId), option, { merge: true });
}

export function clearOptions(meetupId) {
    return getDocs(subCollection(meetupId, "options")).then(function gotACB(snapshot) {
        return Promise.all(snapshot.docs.map(function removeACB(document) {
            return deleteDoc(document.ref);
        }));
    });
}

export function appendActivity(meetupId, event) {
    return addDoc(subCollection(meetupId, "activity"), {
        ...event,
        createdAt: serverTimestamp(),
    });
}

// --- live subscriptions ---

export function subscribeMyMeetups(uid, receivedACB, failedACB) {
    const mine = query(collection(db, MEETUPS), where("memberIds", "array-contains", uid));
    return onSnapshot(mine, function gotMineACB(snapshot) {
        const meetups = [];
        snapshot.forEach(function eachACB(document) {
            meetups.push(plainify({ id: document.id, ...document.data() }));
        });
        receivedACB(meetups);
    }, failedACB);
}

export function subscribeMeetup(meetupId, receivedACB, failedACB) {
    return onSnapshot(meetupDoc(meetupId), function gotMeetupACB(snapshot) {
        receivedACB(snapshot.exists() ? plainify({ id: snapshot.id, ...snapshot.data() }) : null);
    }, failedACB);
}

export function subscribeSubCollection(meetupId, sub, receivedACB, failedACB) {
    return onSnapshot(subCollection(meetupId, sub), function gotSubACB(snapshot) {
        receivedACB(keyById(snapshot));
    }, failedACB);
}

export function subscribeActivity(meetupId, receivedACB, failedACB) {
    const recent = query(subCollection(meetupId, "activity"), orderBy("createdAt", "desc"), limit(12));
    return onSnapshot(recent, function gotActivityACB(snapshot) {
        const events = [];
        snapshot.forEach(function eachACB(document) {
            events.push(plainify({ id: document.id, ...document.data() }));
        });
        receivedACB(events);
    }, failedACB);
}
