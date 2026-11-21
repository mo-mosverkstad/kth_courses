import { connect } from "/src/vueRedux/connect.js";
import { InviteView } from "/src/views/inviteView.jsx";
import { SuspenseView } from "/src/views/suspenseView.jsx";
import * as intent from "/src/model/actions.js";
import { toastShown } from "/src/model/slices/uiSlice.js";
import {
    selectActivity, selectIsOrganiser, selectMeetup, selectResponseStatus,
} from "/src/model/selectors.js";

function InviteScreen(props) {
    if (!props.title) {
        return <SuspenseView label="Opening this Catch Up" rows={3} />;
    }
    return <InviteView {...props} />;
}

function mapStateACB(state) {
    const meetup = selectMeetup(state);
    return {
        title: meetup?.title || "",
        inviteCode: meetup?.inviteCode || "",
        link: meetup
            ? `${window.location.origin}${window.location.pathname}#/join/${meetup.inviteCode}`
            : "",
        status: selectResponseStatus(state),
        activity: selectActivity(state),
        isOrganiser: selectIsOrganiser(state),
    };
}

function mapDispatchACB(dispatch) {
    return {
        copyLink: function copyLinkACB(link) {
            // Clipboard access is a browser capability, not application state,
            // but the confirmation the user sees is: it goes through the store.
            function confirmACB() {
                dispatch(toastShown({ text: "Invite link copied", tone: "ok" }));
            }
            function failACB() {
                dispatch(toastShown({ text: `Copy failed. The link is ${link}`, tone: "warn" }));
            }
            if (navigator.clipboard?.writeText) {
                navigator.clipboard.writeText(link).then(confirmACB, failACB);
            } else {
                failACB();
            }
        },
        openVoting: function openVotingACB() {
            dispatch(intent.votingOpened());
        },
    };
}

export const InvitePresenter = connect(mapStateACB, mapDispatchACB)(InviteScreen);
