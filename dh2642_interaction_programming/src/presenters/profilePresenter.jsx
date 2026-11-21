import { connect } from "/src/vueRedux/connect.js";
import { ProfileView } from "/src/views/profileView.jsx";
import * as intent from "/src/model/actions.js";
import { profileFormChanged } from "/src/model/slices/formsSlice.js";
import { selectRequest } from "/src/model/selectors.js";

function mapStateACB(state) {
    const defaults = state.auth.defaults;
    const form = state.forms.profile;
    return {
        displayName: state.auth.displayName,
        email: state.auth.email,
        // Saved defaults are the source of truth; the form slice only holds
        // edits made since the screen was opened.
        form: {
            startingArea: form.startingArea || defaults.startingArea || "",
            maxTravelMinutes: form.maxTravelMinutes ?? defaults.maxTravelMinutes,
            needs: form.needs.length ? form.needs : (defaults.needs || []),
            shareStartingArea: form.shareStartingArea ?? defaults.shareStartingArea,
        },
        savedRecently: selectRequest(state, "defaults").status === "fulfilled",
    };
}

function mapDispatchACB(dispatch) {
    return {
        change: function changeACB(changes) {
            dispatch(profileFormChanged(changes));
        },
        save: function saveACB(form) {
            dispatch(intent.defaultsSubmitted(form));
        },
        signOut: function signOutACB() {
            dispatch(intent.signOutRequested());
        },
    };
}

export const ProfilePresenter = connect(mapStateACB, mapDispatchACB)(ProfileView);
