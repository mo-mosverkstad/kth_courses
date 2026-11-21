import { connect } from "/src/vueRedux/connect.js";
import { CreateView } from "/src/views/createView.jsx";
import * as intent from "/src/model/actions.js";
import {
    draftChanged, draftWindowAdded, draftWindowRemoved, emptyDraft,
} from "/src/model/slices/meetupSlice.js";
import { createFormChanged } from "/src/model/slices/formsSlice.js";
import { router } from "/src/router.js";
import { selectDraft, selectRequest } from "/src/model/selectors.js";

function mapStateACB(state) {
    const draft = selectDraft(state) || emptyDraft;
    return {
        // The form's two scratch fields live in the forms slice; the rest of
        // the draft is the meeting being built.
        draft: { ...draft, ...state.forms.create },
        busy: selectRequest(state, "createMeetup").status === "pending",
    };
}

function mapDispatchACB(dispatch) {
    return {
        change: function changeACB(changes) {
            const scratch = {};
            const real = {};
            Object.keys(changes).forEach(function splitACB(key) {
                if (key === "newWindowStart" || key === "newWindowEnd") {
                    scratch[key] = changes[key];
                } else {
                    real[key] = changes[key];
                }
            });
            if (Object.keys(scratch).length) {
                dispatch(createFormChanged(scratch));
            }
            if (Object.keys(real).length) {
                dispatch(draftChanged(real));
            }
        },
        addWindow: function addWindowACB(window) {
            dispatch(draftWindowAdded(window));
            dispatch(createFormChanged({ newWindowStart: "", newWindowEnd: "" }));
        },
        removeWindow: function removeWindowACB(index) {
            dispatch(draftWindowRemoved(index));
        },
        create: function createACB() {
            dispatch(intent.meetupCreationRequested({
                navigateACB: function navigateACB(meetupId) {
                    router.push(`/meetup/${meetupId}/invite`);
                },
            }));
        },
    };
}

export const CreatePresenter = connect(mapStateACB, mapDispatchACB)(CreateView);
