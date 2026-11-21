import { configureStore, createListenerMiddleware } from "@reduxjs/toolkit";
import { authReducer } from "./slices/authSlice.js";
import { formsReducer } from "./slices/formsSlice.js";
import { meetupReducer } from "./slices/meetupSlice.js";
import { requestsReducer } from "./slices/requestsSlice.js";
import { uiReducer } from "./slices/uiSlice.js";

// The listener middleware is how every side effect reaches the outside world.
// Persistence, external fetches and live subscriptions are all registered as
// listeners on actions in model/sideEffects.js, which means no presenter and
// no view ever calls Firebase or fetch directly.
export const listener = createListenerMiddleware();

export const store = configureStore({
    reducer: {
        auth: authReducer,
        forms: formsReducer,
        meetup: meetupReducer,
        requests: requestsReducer,
        ui: uiReducer,
    },
    middleware: function middlewareACB(getDefaultMiddleware) {
        return getDefaultMiddleware().prepend(listener.middleware);
    },
});

// Handy during development and examination: inspect the application state
// from the browser console.
if (typeof window !== "undefined") {
    window.store = store;
}
