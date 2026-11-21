// Presenter = two pure mappings + which view to show. No fetch, no Firebase,
// no component state, no markup.
import { connect } from "/src/vueRedux/connect.js";
import { SignInView } from "/src/views/signInView.jsx";
import * as intent from "/src/model/actions.js";
import { signInFormChanged } from "/src/model/slices/formsSlice.js";
import { selectRequest } from "/src/model/selectors.js";

function mapStateACB(state) {
    const form = state.forms.signIn;
    return {
        form,
        mode: form.mode,
        error: state.auth.error,
        busy: selectRequest(state, "auth").status === "pending" ||
              selectRequest(state, "join").status === "pending",
        signedIn: state.auth.status === "signedIn",
    };
}

function mapDispatchACB(dispatch) {
    return {
        change: function changeACB(changes) {
            dispatch(signInFormChanged(changes));
        },
        signIn: function signInACB(form) {
            dispatch(intent.signInRequested({ email: form.email, password: form.password }));
        },
        signUp: function signUpACB(form) {
            dispatch(intent.signUpRequested({
                email: form.email,
                password: form.password,
                displayName: form.displayName,
            }));
        },
        join: function joinACB(code) {
            dispatch(intent.meetupJoinRequested({ code }));
        },
    };
}

export const SignInPresenter = connect(mapStateACB, mapDispatchACB)(SignInView);
