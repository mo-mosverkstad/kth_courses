import { connect } from "/src/vueRedux/connect.js";
import { OverviewView } from "/src/views/overviewView.jsx";
import { SuspenseView } from "/src/views/suspenseView.jsx";
import { goToStage } from "/src/router.js";
import {
    selectIsOrganiser, selectMeetup, selectMyAvailability, selectResponseStatus,
} from "/src/model/selectors.js";

// Which step matters next depends on what this user has already done rather
// than on a fixed order, so it is derived from the state.
function nextStepFor(meetup, myIntervals, status, isOrganiser, memberCount) {
    // Inviting comes first for an organiser who is still alone: everybody else
    // needs time to answer, so this is the step that unblocks the group.
    if (isOrganiser && memberCount <= 1) {
        return {
            label: "Invite the group",
            hint: "Share the link or read out the code. Nobody can be compared until at least two people have answered.",
            action: "Get the invite link",
            path: "invite",
        };
    }
    if (myIntervals.length === 0) {
        return {
            label: "Add your availability",
            hint: "Nobody can be compared until you say when you are free.",
            action: "Add my availability",
            path: "availability",
        };
    }
    if (meetup.status === "confirmed") {
        return {
            label: "The plan is settled",
            hint: "See the confirmed time, space and your own journey.",
            action: "See the result",
            path: "result",
        };
    }
    if (meetup.status === "voting") {
        return {
            label: "Voting is open",
            hint: `${status.answered} of ${status.total} have added availability.`,
            action: "Go to the vote",
            path: "vote",
        };
    }
    return {
        label: "Compare the options",
        hint: "Spaces, travel times per member and weather, scored and explained.",
        action: "See the options",
        path: "options",
    };
}

function OverviewScreen(props) {
    if (!props.ready) {
        return <SuspenseView label="Opening this Catch Up" rows={4} />;
    }
    function goNextACB() {
        props.navigate(props.nextPath);
    }
    function goInviteACB() {
        props.navigate("invite");
    }
    return <OverviewView {...props} goNext={goNextACB} goInvite={goInviteACB} />;
}

function mapStateACB(state) {
    const meetup = selectMeetup(state);
    const status = selectResponseStatus(state);
    if (!meetup) {
        return { ready: false };
    }
    const isOrganiser = selectIsOrganiser(state);
    const memberCount = (meetup.memberIds || []).length;
    const next = nextStepFor(
        meetup, selectMyAvailability(state), status, isOrganiser, memberCount,
    );
    return {
        ready: true,
        title: meetup.title,
        purpose: meetup.purpose,
        durationMinutes: meetup.durationMinutes,
        decisionDeadline: meetup.decisionDeadline,
        windows: meetup.windows || [],
        status,
        // The invite code is shown here too, not only on the Invite screen:
        // sharing it is the one thing a new organiser always needs, and making
        // them find a screen for it was the discoverability hole.
        inviteCode: meetup.inviteCode || "",
        memberCount,
        nextLabel: next.label,
        nextHint: next.hint,
        nextAction: next.action,
        nextPath: next.path,
    };
}

function mapDispatchACB() {
    return {
        navigate: function navigateACB(stage) {
            goToStage(stage);
        },
    };
}

export const OverviewPresenter = connect(mapStateACB, mapDispatchACB)(OverviewScreen);
