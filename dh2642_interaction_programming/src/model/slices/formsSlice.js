import { createSlice } from "@reduxjs/toolkit";

// Form contents live in the application state, not in component state.
//
// The course guidance is explicit about this: there are very few reasons for
// component state unless the component is meant to be universal. Keeping the
// in-progress text here means a half-filled form survives a navigation, and a
// presenter never has to own data.
const initialState = {
    signIn: { mode: "signIn", email: "", password: "", displayName: "", code: "" },
    availability: { startingAreaDraft: "", maxTravelMinutes: 35, needs: [] },
    profile: { startingArea: "", maxTravelMinutes: 35, needs: [], shareStartingArea: false },
    create: { newWindowStart: "", newWindowEnd: "" },
};

const formsSlice = createSlice({
    name: "forms",
    initialState,
    reducers: {
        signInFormChanged(state, action) {
            state.signIn = { ...state.signIn, ...action.payload };
        },
        availabilityFormChanged(state, action) {
            state.availability = { ...state.availability, ...action.payload };
        },
        availabilityFormSeeded(state, action) {
            state.availability = { ...state.availability, ...action.payload };
        },
        profileFormChanged(state, action) {
            state.profile = { ...state.profile, ...action.payload };
        },
        profileFormSeeded(state, action) {
            state.profile = { ...initialState.profile, ...action.payload };
        },
        createFormChanged(state, action) {
            state.create = { ...state.create, ...action.payload };
        },
    },
});

export const {
    signInFormChanged, availabilityFormChanged, availabilityFormSeeded,
    profileFormChanged, profileFormSeeded, createFormChanged,
} = formsSlice.actions;

export const formsReducer = formsSlice.reducer;
