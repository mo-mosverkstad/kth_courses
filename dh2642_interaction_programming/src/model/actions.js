// Intention actions: what a presenter is allowed to say.
//
// A presenter dispatches exactly one of these per user gesture. Everything
// that has to happen afterwards (fetching, persisting, logging activity) is
// handled by the side effects registered in sideEffects.js. This is what keeps
// presenters free of fetch and Firebase calls.
import { createAction } from "@reduxjs/toolkit";

export const signInRequested = createAction("app/signInRequested");
export const signUpRequested = createAction("app/signUpRequested");
export const signOutRequested = createAction("app/signOutRequested");

export const myMeetupsSubscriptionRequested = createAction("app/myMeetupsSubscriptionRequested");

export const meetupCreationRequested = createAction("app/meetupCreationRequested");
export const meetupJoinRequested = createAction("app/meetupJoinRequested");
export const meetupSubscriptionRequested = createAction("app/meetupSubscriptionRequested");
export const meetupSubscriptionEnded = createAction("app/meetupSubscriptionEnded");

export const startingAreaSubmitted = createAction("app/startingAreaSubmitted");
export const preferencesSubmitted = createAction("app/preferencesSubmitted");
export const availabilitySubmitted = createAction("app/availabilitySubmitted");
export const defaultsSubmitted = createAction("app/defaultsSubmitted");

export const optionsRequested = createAction("app/optionsRequested");
export const optionRefreshRequested = createAction("app/optionRefreshRequested");

export const calendarExportRequested = createAction("app/calendarExportRequested");

export const voteCast = createAction("app/voteCast");
export const votingOpened = createAction("app/votingOpened");
export const decisionConfirmed = createAction("app/decisionConfirmed");
export const decisionReopened = createAction("app/decisionReopened");
