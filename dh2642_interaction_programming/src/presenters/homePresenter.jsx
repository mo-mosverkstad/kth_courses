import { connect } from "/src/vueRedux/connect.js";
import { HomeView } from "/src/views/homeView.jsx";
import { SuspenseView } from "/src/views/suspenseView.jsx";
import { ErrorPanelView } from "/src/views/errorPanelView.jsx";
import * as intent from "/src/model/actions.js";
import { draftStarted } from "/src/model/slices/meetupSlice.js";
import { router } from "/src/router.js";
import { selectMyMeetupSummaries, selectRequest } from "/src/model/selectors.js";

// Selecting between the loading, error and content views is a presenter job.
// This function contains no markup of its own: it only chooses a view.
function HomeScreen(props) {
    if (!props.signedIn) {
        return <SuspenseView label="Checking your session" rows={2} />;
    }
    if (!props.loaded) {
        return <SuspenseView label="Loading your Catch Ups" rows={4} />;
    }
    if (props.error) {
        return <ErrorPanelView title="Could not load your Catch Ups"
                               message={props.error} retry={props.retry} />;
    }
    return <HomeView {...props} />;
}

function mapStateACB(state) {
    return {
        summaries: selectMyMeetupSummaries(state),
        signedIn: state.auth.status === "signedIn",
        loaded: state.meetup.myMeetupsLoaded,
        error: selectRequest(state, "myMeetups").error,
        defaults: state.auth.defaults,
    };
}

function mapDispatchACB(dispatch) {
    return {
        open: function openACB(meetupId) {
            router.push(`/meetup/${meetupId}/overview`);
        },
        createNew: function createNewACB() {
            dispatch(draftStarted());
            router.push("/create");
        },
        retry: function retryACB() {
            dispatch(intent.myMeetupsSubscriptionRequested());
        },
    };
}

export const HomePresenter = connect(mapStateACB, mapDispatchACB)(HomeScreen);
