// Routing. The route is treated as application-wide state: the presenters do
// not read location, they read the store, and the router only decides which
// presenter is mounted. Opening a meeting URL dispatches the subscription
// intention, so a deep link or a page reload restores the same screen.
import { createRouter, createWebHashHistory } from "vue-router";
import { h } from "vue";
import { store } from "/src/model/store.js";
import * as intent from "/src/model/actions.js";
import { draftStarted, meetupOpened } from "/src/model/slices/meetupSlice.js";
import {
    pendingPathCleared, pendingPathStored, routeChanged,
} from "/src/model/slices/uiSlice.js";

import { AvailabilityPresenter } from "/src/presenters/availabilityPresenter.jsx";
import { CreatePresenter } from "/src/presenters/createPresenter.jsx";
import { HomePresenter } from "/src/presenters/homePresenter.jsx";
import { InvitePresenter } from "/src/presenters/invitePresenter.jsx";
import { OptionsPresenter } from "/src/presenters/optionsPresenter.jsx";
import { OverviewPresenter } from "/src/presenters/overviewPresenter.jsx";
import { ProfilePresenter } from "/src/presenters/profilePresenter.jsx";
import { ResultPresenter } from "/src/presenters/resultPresenter.jsx";
import { SignInPresenter } from "/src/presenters/signInPresenter.jsx";
import { VotePresenter } from "/src/presenters/votePresenter.jsx";

function mount(presenter) {
    return { render: function renderPresenterACB() { return h(presenter); } };
}

export const router = createRouter({
    history: createWebHashHistory(),
    routes: [
        { path: "/", redirect: "/home" },
        { path: "/home", component: mount(HomePresenter) },
        { path: "/signin", component: mount(SignInPresenter) },
        { path: "/profile", component: mount(ProfilePresenter) },
        { path: "/create", component: mount(CreatePresenter) },
        { path: "/join/:code", component: mount(SignInPresenter) },
        { path: "/meetup/:id/overview", component: mount(OverviewPresenter) },
        { path: "/meetup/:id/invite", component: mount(InvitePresenter) },
        { path: "/meetup/:id/availability", component: mount(AvailabilityPresenter) },
        { path: "/meetup/:id/options", component: mount(OptionsPresenter) },
        { path: "/meetup/:id/vote", component: mount(VotePresenter) },
        { path: "/meetup/:id/result", component: mount(ResultPresenter) },
        { path: "/:pathMatch(.*)*", redirect: "/home" },
    ],
});

// Keep the store's idea of "which meeting is open" in step with the URL, and
// subscribe or unsubscribe the live listeners accordingly.
router.afterEach(function routeChangedACB(to) {
    const state = store.getState();
    const meetupId = to.params?.id || null;

    store.dispatch(routeChanged(to.path));

    if (meetupId && meetupId !== state.meetup.currentId) {
        store.dispatch(meetupOpened(meetupId));
        store.dispatch(intent.meetupSubscriptionRequested(meetupId));
    }
    if (!meetupId && state.meetup.currentId) {
        store.dispatch(intent.meetupSubscriptionEnded());
    }
    if (to.path === "/create" && !state.meetup.draft) {
        store.dispatch(draftStarted());
    }
    if (to.params?.code) {
        store.dispatch(intent.meetupJoinRequested({
            code: to.params.code,
            navigateACB: function navigateACB(id) {
                router.push(`/meetup/${id}/overview`);
            },
        }));
    }
});

function needsAuth(path) {
    return path.startsWith("/meetup") || path === "/create" ||
           path === "/profile" || path === "/home";
}

// While Firebase is still resolving the session, auth.status is "unknown" and
// we must not redirect: doing so would bounce a signed-in user to the sign-in
// screen on every reload. Only a settled "signedOut" redirects.
router.beforeEach(function guardACB(to) {
    const status = store.getState().auth.status;
    if (needsAuth(to.path) && status === "signedOut") {
        // Remember where they were going, so signing in resumes the deep link
        // instead of dumping them on the home screen.
        store.dispatch(pendingPathStored(to.fullPath));
        return "/signin";
    }
    return true;
});

// Auth settles asynchronously, after the first navigation has already
// happened, so the store drives the redirect rather than the guard alone.
let lastStatus = store.getState().auth.status;
store.subscribe(function authSettledACB() {
    const state = store.getState();
    const status = state.auth.status;
    if (status === lastStatus) {
        return;
    }
    lastStatus = status;
    const path = router.currentRoute.value.path;

    if (status === "signedOut" && needsAuth(path)) {
        store.dispatch(pendingPathStored(router.currentRoute.value.fullPath));
        router.replace("/signin");
    }
    if (status === "signedIn") {
        const resume = state.ui.pendingPath;
        if (resume && resume !== path) {
            store.dispatch(pendingPathCleared());
            router.replace(resume);
        } else if (path === "/signin" || path === "/") {
            router.replace("/home");
        }
    }
});

// Navigate to a stage of the meeting that is currently open. Presenters use
// this instead of composing URLs, so the id lives in one place.
export function goToStage(stage) {
    const meetupId = store.getState().meetup.currentId;
    if (meetupId) {
        router.push(`/meetup/${meetupId}/${stage}`);
    }
}
