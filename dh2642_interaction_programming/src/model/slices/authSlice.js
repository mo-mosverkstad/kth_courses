import { createSlice } from "@reduxjs/toolkit";

// Who is signed in, plus the recurring defaults that belong to them.
// Nothing here talks to Firebase: authPersistence dispatches into this slice.
const initialState = {
    status: "unknown",          // unknown | signedOut | signedIn
    uid: null,
    displayName: null,
    email: null,
    error: null,
    defaults: {
        startingArea: "",
        startingCoords: null,
        maxTravelMinutes: 35,
        needs: [],
        shareStartingArea: false,
    },
    defaultsLoaded: false,
};

const authSlice = createSlice({
    name: "auth",
    initialState,
    reducers: {
        signedIn(state, action) {
            state.status = "signedIn";
            state.uid = action.payload.uid;
            state.displayName = action.payload.displayName;
            state.email = action.payload.email;
            state.error = null;
        },
        signedOut(state) {
            state.status = "signedOut";
            state.uid = null;
            state.displayName = null;
            state.email = null;
            state.defaults = initialState.defaults;
            state.defaultsLoaded = false;
        },
        authFailed(state, action) {
            state.error = action.payload;
        },
        authErrorCleared(state) {
            state.error = null;
        },
        defaultsLoaded(state, action) {
            state.defaults = { ...initialState.defaults, ...(action.payload || {}) };
            state.defaultsLoaded = true;
        },
        defaultsChanged(state, action) {
            state.defaults = { ...state.defaults, ...action.payload };
        },
    },
});

export const {
    signedIn, signedOut, authFailed, authErrorCleared,
    defaultsLoaded, defaultsChanged,
} = authSlice.actions;

export const authReducer = authSlice.reducer;
