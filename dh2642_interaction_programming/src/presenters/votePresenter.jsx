import { connect } from "/src/vueRedux/connect.js";
import { VoteView } from "/src/views/voteView.jsx";
import { SuspenseView } from "/src/views/suspenseView.jsx";
import * as intent from "/src/model/actions.js";
import { confirmRequested } from "/src/model/slices/uiSlice.js";
import {
    selectActivity, selectIsOrganiser, selectMeetup, selectParticipants,
    selectReadiness, selectSortedOptions, selectVoteTally, travelRowsFor,
} from "/src/model/selectors.js";

function VoteScreen(props) {
    if (!props.ready) {
        return <SuspenseView label="Opening the vote" rows={4} />;
    }
    return <VoteView {...props} />;
}

function mapStateACB(state) {
    const participants = selectParticipants(state);
    return {
        ready: Boolean(selectMeetup(state)),
        options: selectSortedOptions(state),
        tally: selectVoteTally(state),
        isOrganiser: selectIsOrganiser(state),
        readiness: selectReadiness(state),
        activity: selectActivity(state),
        travelRowsFor: function rowsForACB(option) {
            return travelRowsFor(option, participants);
        },
    };
}

function mapDispatchACB(dispatch) {
    return {
        vote: function voteACB(optionId) {
            dispatch(intent.voteCast({ optionId }));
        },
        // Confirming is hard to undo for the whole group, so it goes through
        // the confirmation dialog with its consequence spelled out.
        requestConfirm: function requestConfirmACB(optionId) {
            dispatch(confirmRequested({
                title: "Confirm this plan for everybody?",
                body: "This closes the vote and sets the time and space for the whole group.",
                consequence: "Every member's device will update immediately.",
                confirmLabel: "Confirm the plan",
                action: "decisionConfirmed",
                optionId,
            }));
        },
    };
}

export const VotePresenter = connect(mapStateACB, mapDispatchACB)(VoteScreen);
