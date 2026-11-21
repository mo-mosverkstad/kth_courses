import { connect } from "/src/vueRedux/connect.js";
import { ResultView } from "/src/views/resultView.jsx";
import * as intent from "/src/model/actions.js";
import { confirmRequested } from "/src/model/slices/uiSlice.js";
import { goToStage } from "/src/router.js";
import {
    selectConfirmedOption, selectIsOrganiser, selectMeetup, selectParticipants,
    travelRowsFor,
} from "/src/model/selectors.js";

function leaveByFor(option, minutes) {
    if (!option || !minutes) {
        return null;
    }
    const leave = new Date(new Date(option.window.start).getTime() - minutes * 60000);
    return leave.toLocaleTimeString("sv-SE", { timeStyle: "short" });
}

function mapStateACB(state) {
    const option = selectConfirmedOption(state);
    const participants = selectParticipants(state);
    const myMinutes = option?.travel?.[state.auth.uid]?.minutes ?? null;
    return {
        title: selectMeetup(state)?.title || "",
        option,
        travelRows: option ? travelRowsFor(option, participants) : [],
        myMinutes,
        leaveBy: leaveByFor(option, myMinutes),
        isOrganiser: selectIsOrganiser(state),
    };
}

function mapDispatchACB(dispatch) {
    return {
        goToVote: function goToVoteACB() {
            goToStage("vote");
        },
        exportCalendar: function exportCalendarACB(option) {
            dispatch(intent.calendarExportRequested({ optionId: option.id }));
        },
        requestReopen: function requestReopenACB() {
            dispatch(confirmRequested({
                title: "Reopen the decision?",
                body: "The confirmed plan is cleared and the group votes again.",
                consequence: "Everybody who already saw the confirmed plan will see it disappear.",
                confirmLabel: "Reopen",
                action: "decisionReopened",
            }));
        },
    };
}

export const ResultPresenter = connect(mapStateACB, mapDispatchACB)(ResultView);
