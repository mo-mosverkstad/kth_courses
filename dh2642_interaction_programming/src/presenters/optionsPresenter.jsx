import { connect } from "/src/vueRedux/connect.js";
import { OptionsScreenView } from "/src/views/optionsScreenView.jsx";
import { SuspenseView } from "/src/views/suspenseView.jsx";
import { ErrorPanelView } from "/src/views/errorPanelView.jsx";
import * as intent from "/src/model/actions.js";
import { DEFAULT_AREA } from "/src/apiConfig.js";
import { groupArea } from "/src/model/candidates.js";
import {
    fairnessEmphasisToggled, mobilePaneChosen, optionSelected, sortChosen,
} from "/src/model/slices/uiSlice.js";
import {
    selectBreakpoint, selectMeetup, selectParticipants, selectRequest,
    selectSelectedOption, selectSortedOptions, selectUi, travelRowsFor,
} from "/src/model/selectors.js";

function OptionsScreen(props) {
    if (!props.ready) {
        return <SuspenseView label="Opening this Catch Up" rows={4} />;
    }
    // A pending search only replaces the screen while there is nothing to
    // show. Once options exist they stay on screen and the status bar reports
    // the refresh, so the user can keep reading and comparing.
    if (props.searching && props.options.length === 0) {
        return <SuspenseView label="Finding spaces, travel times and weather" rows={6} />;
    }
    if (props.searchError && props.options.length === 0) {
        return <ErrorPanelView title="Could not build the options"
                               message={props.searchError}
                               hint="Check that the meeting has at least one window and that members entered a starting area."
                               retry={props.refresh} />;
    }
    return <OptionsScreenView {...props} />;
}

function mapStateACB(state) {
    const participants = selectParticipants(state);
    const options = selectSortedOptions(state);
    const ui = selectUi(state);
    const selected = selectSelectedOption(state);
    const search = selectRequest(state, "options");

    return {
        ready: Boolean(selectMeetup(state)),
        breakpoint: selectBreakpoint(state),
        pane: ui.mobilePane,
        options,
        option: selected,
        selectedId: selected?.id || null,
        sortBy: ui.sortBy,
        fairnessEmphasis: ui.fairnessEmphasis,
        participantCount: participants.length,
        searching: search.status === "pending",
        searchError: search.error,
        // Where we looked, so a wrong result is attributable rather than
        // mysterious.
        searchArea: groupArea(participants, DEFAULT_AREA),
        canVote: Boolean(selectMeetup(state)),
        myVotes: state.auth.uid ? (state.meetup.votes[state.auth.uid]?.optionIds || []) : [],

        spaces: options.map(function spaceACB(option) {
            return { ...option.space, id: option.id, name: option.space.name };
        }),
        starts: participants
            .filter(function hasCoordsACB(participant) {
                return Boolean(participant.startingCoords);
            })
            .map(function startACB(participant) {
                return {
                    name: participant.displayName || "Member",
                    lat: participant.startingCoords.lat,
                    lon: participant.startingCoords.lon,
                };
            }),

        travelRows: selected ? travelRowsFor(selected, participants) : [],
        travelRowsFor: function rowsForACB(option) {
            return travelRowsFor(option, participants);
        },
        requestFor: function requestForACB(optionId) {
            return selectRequest(state, `option:${optionId}`);
        },
    };
}

function mapDispatchACB(dispatch) {
    return {
        select: function selectACB(optionId) {
            dispatch(optionSelected(optionId));
        },
        changeSort: function changeSortACB(sortBy) {
            dispatch(sortChosen(sortBy));
        },
        choosePane: function choosePaneACB(pane) {
            dispatch(mobilePaneChosen(pane));
        },
        toggleEmphasis: function toggleEmphasisACB() {
            dispatch(fairnessEmphasisToggled());
        },
        refresh: function refreshACB() {
            dispatch(intent.optionsRequested());
        },
        retry: function retryACB(optionId) {
            dispatch(intent.optionRefreshRequested({ optionId }));
        },
        vote: function voteACB(optionId) {
            dispatch(intent.voteCast({ optionId }));
        },
    };
}

export const OptionsPresenter = connect(mapStateACB, mapDispatchACB)(OptionsScreen);
