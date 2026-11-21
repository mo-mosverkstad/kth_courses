// Authentication and the per-user defaults document.
//
// The presenters only ever request a sign-in or a sign-out. The rest of the
// system finds out through onAuthStateChanged, which is wired to the store in
// model/sideEffects.js - so no presenter has to coordinate "sign in, then also
// load my defaults, then also subscribe to my meetings".
import {
    createUserWithEmailAndPassword, onAuthStateChanged,
    signInWithEmailAndPassword, signOut, updateProfile,
} from "firebase/auth";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { auth, db, USERS } from "./firebase.js";

export function observeAuth(changedACB) {
    return onAuthStateChanged(auth, function authChangedACB(user) {
        changedACB(user ? {
            uid: user.uid,
            displayName: user.displayName || user.email?.split("@")[0] || "Member",
            email: user.email,
        } : null);
    });
}

export function signInWithPassword(email, password) {
    return signInWithEmailAndPassword(auth, email, password);
}

export function createAccount(email, password, displayName) {
    return createUserWithEmailAndPassword(auth, email, password)
        .then(function namedACB(credential) {
            if (displayName) {
                return updateProfile(credential.user, { displayName })
                    .then(function doneACB() { return credential; });
            }
            return credential;
        });
}

export function signOutNow() {
    return signOut(auth);
}

export function readDefaults(uid) {
    return getDoc(doc(db, USERS, uid)).then(function gotDefaultsACB(snapshot) {
        return snapshot.exists() ? (snapshot.data().defaults || {}) : {};
    });
}

export function writeDefaults(uid, defaults) {
    return setDoc(doc(db, USERS, uid), { defaults }, { merge: true });
}
