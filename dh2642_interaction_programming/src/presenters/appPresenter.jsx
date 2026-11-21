import { connect } from "/src/vueRedux/connect.js";
import { AppShellView } from "/src/views/appShellView.jsx";
import * as intent from "/src/model/actions.js";
import {
    confirmDismissed, toastDismissed,
} from "/src/model/slices/uiSlice.js";
import { draftStarted } from "/src/model/slices/meetupSlice.js";
import { goToStage, router } from "/src/router.js";
import {
    selectBreakpoint, selectMeetup, selectMyMeetupSummaries, selectPendingLabels,
    selectProgress, selectUi,
} from "/src/model/selectors.js";

const STAGES = [
    { path: "overview", label: "Overview" },
    { path: "invite", label: "Invite" },
    { path: "availability", label: "Availability" },
    { path: "options", label: "Options" },
    { path: "vote", label: "Vote" },
    { path: "result", label: "Result" },
];

function mapStateACB(state) {
    const meetup = selectMeetup(state);
    const ui = selectUi(state);
    const summaries = selectMyMeetupSummaries(state);
    const path = ui.route;

    return {
        breakpoint: selectBreakpoint(state),
        authStatus: state.auth.status,
        activePath: path,
        inMeetup: path.startsWith("/meetup"),
        stages: STAGES,
        stageSubtitle: meetup
            ? `${meetup.title} · ${meetup.status === "confirmed" ? "confirmed" : meetup.status}`
            : "",
        heading: meetup && path.startsWith("/meetup") ? meetup.title : "Catch Up!",
        subheading: meetup && path.startsWith("/meetup")
            ? "meeting space planner"
            : "Find the space that works for everyone",
        signedIn: state.auth.status === "signedIn",
        displayName: state.auth.displayName,
        pendingLabels: selectPendingLabels(state),
        progress: selectProgress(state, "options"),
        offline: ui.offline === true,
        toasts: ui.toasts,
        confirmDialog: ui.confirmDialog,
        navItems: state.auth.status === "signedIn"
            ? [
                { path: "/home", label: "Home", badge: summaries.needsMe.length || undefined },
                { path: "/create", label: "New" },
                { path: "/profile", label: "Profile" },
            ]
            : [{ path: "/signin", label: "Sign in" }],
    };
}

function mapDispatchACB(dispatch) {
    return {
        navigate: function navigateACB(path) {
            if (path === "/create") {
                dispatch(draftStarted());
            }
            router.push(path);
        },
        navigateStage: function navigateStageACB(stage) {
            goToStage(stage);
        },
        dismissToast: function dismissToastACB(id) {
            dispatch(toastDismissed(id));
        },
        cancelConfirm: function cancelConfirmACB() {
            dispatch(confirmDismissed());
        },
        // The dialog carries the name of the intention to dispatch, so the
        // dialog view stays generic and this stays the only place that maps a
        // confirmation to an action.
        confirmAction: function confirmActionACB(dialog) {
            dispatch(confirmDismissed());
            if (dialog.action === "decisionConfirmed") {
                dispatch(intent.decisionConfirmed({ optionId: dialog.optionId }));
                goToStage("result");
            }
            if (dialog.action === "decisionReopened") {
                dispatch(intent.decisionReopened());
                goToStage("vote");
            }
        },
    };
}

export const AppPresenter = connect(mapStateACB, mapDispatchACB)(AppShellView);
