import { createSlice } from "@reduxjs/toolkit";

// Every external request is tracked here as idle / pending / fulfilled /
// rejected. This is what drives visible system status, and it is also what
// lets the rest of the interface stay usable while a request is in flight:
// nothing blocks on a promise, views just read the state.
//
// Requests are keyed, so a failure is attributable to one space rather than
// to "the app".
const initialState = {
    byKey: {},
    progress: {},    // key -> { done, total, label }
};

const requestsSlice = createSlice({
    name: "requests",
    initialState,
    reducers: {
        requestStarted(state, action) {
            state.byKey[action.payload.key] = {
                status: "pending",
                error: null,
                startedAt: action.payload.startedAt,
                finishedAt: null,
            };
        },
        requestSucceeded(state, action) {
            state.byKey[action.payload.key] = {
                status: "fulfilled",
                error: null,
                startedAt: state.byKey[action.payload.key]?.startedAt || null,
                finishedAt: action.payload.finishedAt,
            };
            delete state.progress[action.payload.key];
        },
        requestFailed(state, action) {
            state.byKey[action.payload.key] = {
                status: "rejected",
                error: action.payload.error,
                startedAt: state.byKey[action.payload.key]?.startedAt || null,
                finishedAt: action.payload.finishedAt,
            };
            delete state.progress[action.payload.key];
        },
        requestProgressed(state, action) {
            state.progress[action.payload.key] = {
                done: action.payload.done,
                total: action.payload.total,
                label: action.payload.label,
            };
        },
        requestCleared(state, action) {
            delete state.byKey[action.payload];
            delete state.progress[action.payload];
        },
    },
});

export const {
    requestStarted, requestSucceeded, requestFailed,
    requestProgressed, requestCleared,
} = requestsSlice.actions;

export const requestsReducer = requestsSlice.reducer;
