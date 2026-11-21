// Single place where Firebase is initialised. Everything else in the
// persistence layer imports db and auth from here, and nothing outside the
// persistence layer imports this file at all.
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { firebaseConfig } from "/src/firebaseConfig.js";

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);

// Collection names are prefixed so this app can share a Firebase project with
// the lab exercises without colliding.
export const USERS = "catchupUsers";
export const MEETUPS = "catchupMeetups";
