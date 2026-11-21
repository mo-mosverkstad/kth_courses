import { createSlice } from "@reduxjs/toolkit";

// The shared meeting: its own fields, plus the per-user sub-collections that
// arrive from Firestore listeners. Every sub-collection is keyed by user id,
// which is what makes simultaneous editing safe.
const initialState = {
    myMeetups: [],              // summaries for the home screen
    myMeetupsLoaded: false,
    currentId: null,
    meetup: null,               // the meeting document
    participants: {},           // uid -> preferences
    availability: {},           // uid -> { intervals }
    options: {},                // optionId -> candidate
    votes: {},                  // uid -> { optionIds }
    activity: [],
    draft: null,                // the create-meeting form, before it exists
};

export const emptyDraft = {
    title: "",
    purpose: "meeting",
    durationMinutes: 120,
    windows: [],
    decisionDeadline: "",
    areaLabel: "",
};

const meetupSlice = createSlice({
    name: "meetup",
    initialState,
    reducers: {
        myMeetupsReceived(state, action) {
            state.myMeetups = action.payload;
            state.myMeetupsLoaded = true;
        },
        meetupOpened(state, action) {
            if (state.currentId !== action.payload) {
                state.currentId = action.payload;
                state.meetup = null;
                state.participants = {};
                state.availability = {};
                state.options = {};
                state.votes = {};
                state.activity = [];
            }
        },
        meetupClosed(state) {
            state.currentId = null;
            state.meetup = null;
            state.participants = {};
            state.availability = {};
            state.options = {};
            state.votes = {};
            state.activity = [];
        },
        // --- data arriving from the live Firestore listeners ---
        meetupReceived(state, action) {
            state.meetup = action.payload;
        },
        participantsReceived(state, action) {
            state.participants = action.payload;
        },
        availabilityReceived(state, action) {
            state.availability = action.payload;
        },
        optionsReceived(state, action) {
            state.options = action.payload;
        },
        votesReceived(state, action) {
            state.votes = action.payload;
        },
        activityReceived(state, action) {
            state.activity = action.payload;
        },
        // --- local intentions; persistence happens as a side effect ---
        draftStarted(state, action) {
            state.draft = { ...emptyDraft, ...(action.payload || {}) };
        },
        draftChanged(state, action) {
            state.draft = { ...state.draft, ...action.payload };
        },
        draftWindowAdded(state, action) {
            state.draft.windows = [...state.draft.windows, action.payload];
        },
        draftWindowRemoved(state, action) {
            state.draft.windows = state.draft.windows.filter(function keepACB(_, index) {
                return index !== action.payload;
            });
        },
        draftDiscarded(state) {
            state.draft = null;
        },
        myPreferencesChanged(state, action) {
            const uid = action.payload.uid;
            state.participants[uid] = { ...(state.participants[uid] || {}), ...action.payload.changes };
        },
        myAvailabilityChanged(state, action) {
            state.availability[action.payload.uid] = { intervals: action.payload.intervals };
        },
        myVoteChanged(state, action) {
            state.votes[action.payload.uid] = { optionIds: action.payload.optionIds };
        },
    },
});

export const {
    myMeetupsReceived, meetupOpened, meetupClosed,
    meetupReceived, participantsReceived, availabilityReceived,
    optionsReceived, votesReceived, activityReceived,
    draftStarted, draftChanged, draftWindowAdded, draftWindowRemoved, draftDiscarded,
    myPreferencesChanged, myAvailabilityChanged, myVoteChanged,
} = meetupSlice.actions;

export const meetupReducer = meetupSlice.reducer;
