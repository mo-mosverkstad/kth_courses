// Bootstrapping.
//
// Order matters: the store exists first, the side effects register themselves
// on it, then the auth observer starts feeding it, and only then is anything
// mounted. Nothing in the view layer ever has to wait for a promise.
import { createApp, h } from "vue";
import "/src/style.css";

import { store } from "/src/model/store.js";
import "/src/model/sideEffects.js";
import { startAuthObserver } from "/src/model/sideEffects.js";
import { connectivityChanged, viewportMeasured } from "/src/model/slices/uiSlice.js";
import { router } from "/src/router.js";
import { AppPresenter } from "/src/presenters/appPresenter.jsx";

// The breakpoint is application state, measured once here and on resize, so
// that no view contains a media query.
function measureViewportACB() {
    store.dispatch(viewportMeasured(window.innerWidth));
}
measureViewportACB();
window.addEventListener("resize", measureViewportACB);

// Losing the network is a system status the user should see, rather than
// silently stale data.
function reportConnectivityACB() {
    store.dispatch(connectivityChanged(navigator.onLine));
}
reportConnectivityACB();
window.addEventListener("online", reportConnectivityACB);
window.addEventListener("offline", reportConnectivityACB);

startAuthObserver();

const app = createApp({
    render: function renderRootACB() {
        return h(AppPresenter);
    },
});
app.use(router);
app.mount("#root");
