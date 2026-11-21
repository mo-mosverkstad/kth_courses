import { createSlice } from "@reduxjs/toolkit";

// Interface state that belongs to the application rather than to one
// component: which option is selected, which pane is showing on a phone, the
// active breakpoint, and transient toasts.
//
// The breakpoint lives here so that no view contains a media query and a
// layout can be forced during a user test without resizing the window.
const initialState = {
    // The route is application-wide state, not something a presenter reads
    // from the router. Keeping it here is what makes the shell re-render on
    // navigation, and it keeps resource ids out of the view layer.
    route: "/",
    breakpoint: "mobile",       // mobile | tabletPortrait | wide
    forcedBreakpoint: null,
    mobilePane: "list",         // list | map
    selectedOptionId: null,
    sortBy: "best",             // best | meanTravel | maxTravel
    fairnessEmphasis: false,
    offline: false,
    pendingPath: null,
    toasts: [],
    confirmDialog: null,
};

let nextToastId = 1;

const uiSlice = createSlice({
    name: "ui",
    initialState,
    reducers: {
        routeChanged(state, action) {
            state.route = action.payload;
            // A new screen starts at the top of its own concern: the map/list
            // tab choice is per-visit, not sticky across the whole app.
            if (!action.payload.endsWith("/options")) {
                state.mobilePane = "list";
            }
        },
        connectivityChanged(state, action) {
            state.offline = action.payload === false;
        },
        viewportMeasured(state, action) {
            const width = action.payload;
            state.breakpoint = width < 600 ? "mobile" : (width < 1024 ? "tabletPortrait" : "wide");
        },
        breakpointForced(state, action) {
            state.forcedBreakpoint = action.payload;
        },
        mobilePaneChosen(state, action) {
            state.mobilePane = action.payload;
        },
        optionSelected(state, action) {
            state.selectedOptionId = action.payload;
        },
        sortChosen(state, action) {
            state.sortBy = action.payload;
        },
        fairnessEmphasisToggled(state) {
            state.fairnessEmphasis = !state.fairnessEmphasis;
        },
        toastShown(state, action) {
            state.toasts = [
                ...state.toasts,
                { id: nextToastId++, text: action.payload.text, tone: action.payload.tone || "ok" },
            ];
        },
        toastDismissed(state, action) {
            state.toasts = state.toasts.filter(function keepACB(toast) {
                return toast.id !== action.payload;
            });
        },
        // Where the user was heading before being asked to sign in, so a deep
        // link into a meeting survives the detour.
        pendingPathStored(state, action) {
            state.pendingPath = action.payload;
        },
        pendingPathCleared(state) {
            state.pendingPath = null;
        },
        confirmRequested(state, action) {
            state.confirmDialog = action.payload;
        },
        confirmDismissed(state) {
            state.confirmDialog = null;
        },
    },
});

export const {
    routeChanged, connectivityChanged, viewportMeasured, breakpointForced,
    mobilePaneChosen, optionSelected, sortChosen, fairnessEmphasisToggled,
    pendingPathStored, pendingPathCleared,
    toastShown, toastDismissed, confirmRequested, confirmDismissed,
} = uiSlice.actions;

export const uiReducer = uiSlice.reducer;
