// Everything derived lives here, computed from the stored state rather than
// stored twice. Presenters read selectors and nothing else.
import { createSelector } from "@reduxjs/toolkit";
import { decisionReadiness, rankOptions, WEIGHTS } from "./scoring.js";

export const selectAuth = function selectAuthACB(state) { return state.auth; };
export const selectUid = function selectUidACB(state) { return state.auth.uid; };
export const selectMeetup = function selectMeetupACB(state) { return state.meetup.meetup; };
export const selectCurrentId = function selectCurrentIdACB(state) { return state.meetup.currentId; };
export const selectDraft = function selectDraftACB(state) { return state.meetup.draft; };
export const selectActivity = function selectActivityACB(state) { return state.meetup.activity; };
export const selectUi = function selectUiACB(state) { return state.ui; };

export const selectBreakpoint = createSelector(
    [function uiACB(state) { return state.ui; }],
    function breakpointACB(ui) {
        return ui.forcedBreakpoint || ui.breakpoint;
    },
);

export const selectParticipants = createSelector(
    [function participantsACB(state) { return state.meetup.participants; }],
    function toListACB(byUid) {
        return Object.values(byUid).sort(function byNameACB(a, b) {
            return String(a.displayName || "").localeCompare(String(b.displayName || ""));
        });
    },
);

export const selectMyParticipant = createSelector(
    [function participantsACB(state) { return state.meetup.participants; }, selectUid],
    function mineACB(byUid, uid) {
        return uid ? (byUid[uid] || null) : null;
    },
);

export const selectMyAvailability = createSelector(
    [function availabilityACB(state) { return state.meetup.availability; }, selectUid],
    function mineACB(byUid, uid) {
        return uid ? (byUid[uid]?.intervals || []) : [];
    },
);

export const selectIsOrganiser = createSelector(
    [selectMeetup, selectUid],
    function organiserACB(meetup, uid) {
        return Boolean(meetup && uid && meetup.organizerId === uid);
    },
);

export const selectResponseStatus = createSelector(
    [selectParticipants, function availabilityACB(state) { return state.meetup.availability; }],
    function statusACB(participants, availability) {
        const rows = participants.map(function rowACB(participant) {
            return {
                uid: participant.uid,
                displayName: participant.displayName || "Member",
                answered: Boolean(availability[participant.uid]?.intervals?.length),
            };
        });
        return {
            rows,
            answered: rows.filter(function answeredACB(row) { return row.answered; }).length,
            total: rows.length,
        };
    },
);

// The ranked, explained options. This is the heart of the app: the ordering
// and every number shown in the explanation come from the same computation.
export const selectRankedOptions = createSelector(
    [
        function optionsACB(state) { return state.meetup.options; },
        selectParticipants,
        function availabilityACB(state) { return state.meetup.availability; },
        function emphasisACB(state) { return state.ui.fairnessEmphasis; },
    ],
    function rankACB(optionsById, participants, availability, fairnessEmphasis) {
        const options = Object.values(optionsById);
        if (options.length === 0) {
            return [];
        }
        // "Weigh fairness higher" is a user control over the model, not a
        // different model: it only raises the weight of the worst journey.
        const weights = fairnessEmphasis
            ? { ...WEIGHTS, maxTravel: WEIGHTS.maxTravel * 2 }
            : WEIGHTS;
        return rankOptions(options, { participants, availability, weights });
    },
);

export const selectSortedOptions = createSelector(
    [selectRankedOptions, function sortACB(state) { return state.ui.sortBy; }],
    function sortedACB(options, sortBy) {
        const copy = [...options];
        if (sortBy === "meanTravel") {
            return copy.sort(function meanACB(a, b) {
                return (a.explanation.stats.mean ?? 1e9) - (b.explanation.stats.mean ?? 1e9);
            });
        }
        if (sortBy === "maxTravel") {
            return copy.sort(function maxACB(a, b) {
                return (a.explanation.stats.max ?? 1e9) - (b.explanation.stats.max ?? 1e9);
            });
        }
        return copy;
    },
);

export const selectSelectedOption = createSelector(
    [selectRankedOptions, function selectedACB(state) { return state.ui.selectedOptionId; }],
    function selectedOptionACB(options, selectedId) {
        if (options.length === 0) {
            return null;
        }
        return options.find(function matchACB(option) { return option.id === selectedId; }) || options[0];
    },
);

export const selectVoteTally = createSelector(
    [
        function votesACB(state) { return state.meetup.votes; },
        function participantsACB(state) { return state.meetup.participants; },
        selectUid,
    ],
    function tallyACB(votes, participants, uid) {
        const byOption = {};
        Object.keys(votes).forEach(function eachVoterACB(voterUid) {
            (votes[voterUid]?.optionIds || []).forEach(function eachOptionACB(optionId) {
                byOption[optionId] = byOption[optionId] || [];
                byOption[optionId].push({
                    uid: voterUid,
                    displayName: participants[voterUid]?.displayName || "Member",
                });
            });
        });
        const voted = Object.keys(votes).filter(function hasVoteACB(voterUid) {
            return (votes[voterUid]?.optionIds || []).length > 0;
        });
        return {
            byOption,
            myVotes: uid ? (votes[uid]?.optionIds || []) : [],
            voted: voted.length,
            total: Object.keys(participants).length,
        };
    },
);

export const selectReadiness = createSelector(
    [
        selectParticipants,
        function availabilityACB(state) { return state.meetup.availability; },
        function votesACB(state) { return state.meetup.votes; },
        function optionsACB(state) { return state.meetup.options; },
    ],
    function readinessACB(participants, availability, votes, options) {
        return decisionReadiness({
            participants,
            availability,
            votes,
            options: Object.values(options),
        });
    },
);

export const selectConfirmedOption = createSelector(
    [selectRankedOptions, selectMeetup],
    function confirmedACB(options, meetup) {
        if (!meetup?.confirmedOptionId) {
            return null;
        }
        return options.find(function matchACB(option) {
            return option.id === meetup.confirmedOptionId;
        }) || null;
    },
);

// Request state, so views can show status without knowing about promises.
export function selectRequest(state, key) {
    return state.requests.byKey[key] || { status: "idle", error: null };
}

export function selectProgress(state, key) {
    return state.requests.progress[key] || null;
}

export const selectAnyPending = createSelector(
    [function byKeyACB(state) { return state.requests.byKey; }],
    function pendingACB(byKey) {
        return Object.keys(byKey).filter(function isPendingACB(key) {
            return byKey[key].status === "pending";
        });
    },
);

export const selectMyMeetupSummaries = createSelector(
    [
        function listACB(state) { return state.meetup.myMeetups; },
        selectUid,
    ],
    function summariesACB(meetups, uid) {
        function bucketForACB(meetup) {
            if (meetup.status === "confirmed") { return "upcoming"; }
            if (meetup.status === "voting") { return "voting"; }
            return "collecting";
        }
        const sorted = [...meetups].sort(function byCreatedACB(a, b) {
            return (b.createdAt || 0) - (a.createdAt || 0);
        });
        return {
            all: sorted,
            upcoming: sorted.filter(function upACB(m) { return bucketForACB(m) === "upcoming"; }),
            voting: sorted.filter(function vtACB(m) { return bucketForACB(m) === "voting"; }),
            collecting: sorted.filter(function clACB(m) { return bucketForACB(m) === "collecting"; }),
            needsMe: sorted.filter(function needsACB(m) {
                return m.status !== "confirmed" && !(m.respondedIds || []).includes(uid);
            }),
        };
    },
);

// Shape one option's travel data into view rows: one row per participant,
// carrying that person's own limit so the view can mark an unfair journey.
export function travelRowsFor(option, participants) {
    return (participants || []).map(function rowACB(participant) {
        const entry = option?.travel?.[participant.uid];
        return {
            uid: participant.uid,
            name: participant.displayName || "Member",
            minutes: entry?.minutes ?? null,
            estimated: Boolean(entry?.estimated),
            limit: participant.maxTravelMinutes || null,
        };
    });
}

// Human-readable labels for whatever is currently in flight, so the status bar
// says what is happening rather than just spinning.
const REQUEST_LABELS = {
    auth: "Signing in",
    defaults: "Loading your defaults",
    createMeetup: "Creating the Catch Up",
    join: "Joining",
    geocode: "Looking up the area",
    options: "Finding spaces, travel times and weather",
    savePreferences: "Saving your preferences",
    saveAvailability: "Saving your availability",
    saveVote: "Saving your vote",
    status: "Updating the meeting",
};

export const selectPendingLabels = createSelector(
    [selectAnyPending],
    function labelsACB(keys) {
        return keys.map(function labelACB(key) {
            return REQUEST_LABELS[key] || "Working";
        });
    },
);
