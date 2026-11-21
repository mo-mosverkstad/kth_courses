import { connect } from "/src/vueRedux/connect.js";
import { AvailabilityView } from "/src/views/availabilityView.jsx";
import { SuspenseView } from "/src/views/suspenseView.jsx";
import * as intent from "/src/model/actions.js";
import { availabilityFormChanged } from "/src/model/slices/formsSlice.js";
import { goToStage } from "/src/router.js";
import {
    selectCurrentId, selectMeetup, selectMyAvailability, selectMyParticipant,
    selectRequest,
} from "/src/model/selectors.js";

function AvailabilityScreen(props) {
    if (!props.ready) {
        return <SuspenseView label="Opening this Catch Up" rows={4} />;
    }
    return <AvailabilityView {...props} />;
}

function mapStateACB(state) {
    const meetup = selectMeetup(state);
    const mine = selectMyParticipant(state);
    const form = state.forms.availability;
    const geocode = selectRequest(state, "geocode");

    return {
        ready: Boolean(meetup),
        windows: meetup?.windows || [],
        myIntervals: selectMyAvailability(state),
        // The form shows the draft text if present, otherwise what is saved.
        form: {
            startingAreaDraft: form.startingAreaDraft || mine?.startingArea || "",
            maxTravelMinutes: mine?.maxTravelMinutes ?? form.maxTravelMinutes,
            needs: mine?.needs || [],
        },
        resolving: geocode.status === "pending",
        resolveError: geocode.error,
        resolvedArea: mine?.startingCoords ? (mine.startingAreaDisplayName || mine.startingArea) : null,
        savedAt: state.meetup.availability[state.auth.uid]?.updatedAt || null,
        meetupId: selectCurrentId(state),
    };
}

function mapDispatchACB(dispatch) {
    return {
        change: function changeACB(changes) {
            dispatch(availabilityFormChanged(changes));
        },
        resolveArea: function resolveAreaACB(label) {
            dispatch(intent.startingAreaSubmitted({ label }));
        },
        savePreferences: function savePreferencesACB(changes) {
            dispatch(intent.preferencesSubmitted(changes));
        },
        toggleWindow: function toggleWindowACB(window) {
            dispatch(intent.availabilitySubmitted({ window, toggle: true }));
        },
        done: function doneACB() {
            dispatch(intent.optionsRequested());
            goToStage("options");
        },
    };
}

export const AvailabilityPresenter = connect(mapStateACB, mapDispatchACB)(AvailabilityScreen);
