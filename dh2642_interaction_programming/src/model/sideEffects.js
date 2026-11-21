// Every side effect in the application is registered here, on the state
// manager. Presenters dispatch intentions; this file is what talks to the
// network and to Firestore, and then feeds the results back in as actions.
//
// Nothing else in the app imports an api/ or persistence/ module.
import { DEFAULT_AREA } from "/src/apiConfig.js";
import { geocodeArea, searchSpaces } from "/src/api/placeSource.js";
import { fetchTravelTimes } from "/src/api/transitSource.js";
import { fetchWeatherAt } from "/src/api/weatherSource.js";
import {
    createAccount, observeAuth, readDefaults, signInWithPassword,
    signOutNow, writeDefaults,
} from "/src/persistence/authPersistence.js";
import {
    appendActivity, clearOptions, createMeetup, findMeetupByInviteCode,
    joinMeetup, makeInviteCode, subscribeActivity, subscribeMeetup,
    subscribeMyMeetups, subscribeSubCollection, updateMeetup,
    writeAvailability, writeOption, writeParticipant, writeVote,
} from "/src/persistence/meetupPersistence.js";
import { listener, store } from "./store.js";
import { groupArea, shortlistSpaces } from "./candidates.js";
import * as intent from "./actions.js";
import {
    authFailed, defaultsChanged, defaultsLoaded, signedIn, signedOut,
} from "./slices/authSlice.js";
import {
    activityReceived, availabilityReceived, meetupClosed, meetupReceived,
    myAvailabilityChanged, myPreferencesChanged, myVoteChanged,
    myMeetupsReceived, optionsReceived, participantsReceived, votesReceived,
} from "./slices/meetupSlice.js";
import {
    requestFailed, requestProgressed, requestStarted, requestSucceeded,
} from "./slices/requestsSlice.js";
import { optionSelected, toastShown } from "./slices/uiSlice.js";

const on = listener.startListening;

// --- small helpers for tracked requests -------------------------------------

function track(dispatch, key, work) {
    dispatch(requestStarted({ key, startedAt: Date.now() }));
    return Promise.resolve()
        .then(work)
        .then(function okACB(result) {
            dispatch(requestSucceeded({ key, finishedAt: Date.now() }));
            return result;
        })
        .catch(function failACB(error) {
            dispatch(requestFailed({
                key,
                error: error?.message || String(error),
                finishedAt: Date.now(),
            }));
            throw error;
        });
}

let unsubscribers = [];

function addUnsubscriber(fn) {
    if (typeof fn === "function") {
        unsubscribers.push(fn);
    }
}

function dropSubscriptions() {
    unsubscribers.forEach(function stopACB(stop) { stop(); });
    unsubscribers = [];
}

// --- authentication ---------------------------------------------------------

// The presenters only request a sign-in. The rest of the system learns about
// it here, through onAuthStateChanged, and then loads the defaults and
// subscribes to the user's meetings on its own.
// How long we wait for Firebase to report a session before deciding there is
// none. Without this the whole app sits on "checking your session" forever if
// the auth endpoint is slow, blocked by a proxy, or unavailable offline.
const AUTH_TIMEOUT_MS = 4000;

export function startAuthObserver() {
    let settled = false;

    function settleACB() {
        settled = true;
    }

    observeAuth(function authChangedACB(user) {
        settleACB();
        if (user) {
            store.dispatch(signedIn(user));
        } else {
            dropSubscriptions();
            store.dispatch(signedOut());
        }
    });

    setTimeout(function authTimedOutACB() {
        if (!settled && store.getState().auth.status === "unknown") {
            // Treat an unanswered session check as signed out, so the user
            // reaches a sign-in form instead of an indefinite placeholder.
            store.dispatch(signedOut());
            store.dispatch(toastShown({
                text: "Could not reach the sign-in service. You can still try signing in.",
                tone: "warn",
            }));
        }
    }, AUTH_TIMEOUT_MS);
}

on({
    actionCreator: intent.signInRequested,
    effect: function signInEffectACB(action, api) {
        return track(api.dispatch, "auth", function workACB() {
            return signInWithPassword(action.payload.email, action.payload.password);
        }).catch(function failedACB(error) {
            api.dispatch(authFailed(error?.message || "Sign in failed"));
        });
    },
});

on({
    actionCreator: intent.signUpRequested,
    effect: function signUpEffectACB(action, api) {
        return track(api.dispatch, "auth", function workACB() {
            return createAccount(
                action.payload.email,
                action.payload.password,
                action.payload.displayName,
            );
        }).catch(function failedACB(error) {
            api.dispatch(authFailed(error?.message || "Could not create the account"));
        });
    },
});

on({
    actionCreator: intent.signOutRequested,
    effect: function signOutEffectACB(action, api) {
        dropSubscriptions();
        return signOutNow().catch(function failedACB(error) {
            api.dispatch(authFailed(error?.message || "Sign out failed"));
        });
    },
});

// When a user appears, load their defaults and subscribe to their meetings.
on({
    actionCreator: signedIn,
    effect: function signedInEffectACB(action, api) {
        const uid = action.payload.uid;
        api.dispatch(intent.myMeetupsSubscriptionRequested(uid));
        return track(api.dispatch, "defaults", function workACB() {
            return readDefaults(uid);
        }).then(function gotACB(defaults) {
            api.dispatch(defaultsLoaded(defaults));
        }).catch(function ignoreACB() {
            api.dispatch(defaultsLoaded({}));
        });
    },
});

on({
    actionCreator: intent.myMeetupsSubscriptionRequested,
    effect: function subscribeMineEffectACB(action, api) {
        addUnsubscriber(subscribeMyMeetups(
            action.payload,
            function gotMineACB(meetups) {
                api.dispatch(myMeetupsReceived(meetups));
            },
            function failedACB(error) {
                api.dispatch(requestFailed({
                    key: "myMeetups",
                    error: error?.message || "Could not load your Catch Ups",
                    finishedAt: Date.now(),
                }));
            },
        ));
    },
});

// Defaults are persisted as a side effect of the state changing.
on({
    actionCreator: intent.defaultsSubmitted,
    effect: function defaultsEffectACB(action, api) {
        const uid = api.getState().auth.uid;
        api.dispatch(defaultsChanged(action.payload));
        if (!uid) {
            return undefined;
        }
        return track(api.dispatch, "defaults", function workACB() {
            return writeDefaults(uid, api.getState().auth.defaults);
        }).then(function savedACB() {
            api.dispatch(toastShown({ text: "Defaults saved", tone: "ok" }));
        }).catch(function ignoreACB() { /* status already in the store */ });
    },
});

// --- opening a meeting: five live listeners --------------------------------

on({
    actionCreator: intent.meetupSubscriptionRequested,
    effect: function subscribeMeetupEffectACB(action, api) {
        const meetupId = action.payload;
        if (!meetupId) {
            return undefined;
        }

        function reportACB(key) {
            return function failedACB(error) {
                api.dispatch(requestFailed({
                    key,
                    error: error?.message || "Live update failed",
                    finishedAt: Date.now(),
                }));
            };
        }

        addUnsubscriber(subscribeMeetup(meetupId, function gotACB(meetup) {
            api.dispatch(meetupReceived(meetup));
        }, reportACB("meetup")));

        addUnsubscriber(subscribeSubCollection(meetupId, "participants", function gotACB(data) {
            api.dispatch(participantsReceived(data));
        }, reportACB("participants")));

        addUnsubscriber(subscribeSubCollection(meetupId, "availability", function gotACB(data) {
            api.dispatch(availabilityReceived(data));
        }, reportACB("availability")));

        addUnsubscriber(subscribeSubCollection(meetupId, "options", function gotACB(data) {
            api.dispatch(optionsReceived(data));
        }, reportACB("options")));

        addUnsubscriber(subscribeSubCollection(meetupId, "votes", function gotACB(data) {
            api.dispatch(votesReceived(data));
        }, reportACB("votes")));

        addUnsubscriber(subscribeActivity(meetupId, function gotACB(events) {
            api.dispatch(activityReceived(events));
        }, reportACB("activity")));

        return undefined;
    },
});

on({
    actionCreator: intent.meetupSubscriptionEnded,
    effect: function unsubscribeEffectACB(action, api) {
        dropSubscriptions();
        const uid = api.getState().auth.uid;
        if (uid) {
            api.dispatch(intent.myMeetupsSubscriptionRequested(uid));
        }
        api.dispatch(meetupClosed());
    },
});

// --- creating and joining ---------------------------------------------------

on({
    actionCreator: intent.meetupCreationRequested,
    effect: function createEffectACB(action, api) {
        const state = api.getState();
        const draft = state.meetup.draft;
        const auth = state.auth;
        if (!draft || !auth.uid) {
            return undefined;
        }

        return track(api.dispatch, "createMeetup", function workACB() {
            return createMeetup({
                title: draft.title.trim() || "Untitled Catch Up",
                purpose: draft.purpose,
                durationMinutes: Number(draft.durationMinutes) || 120,
                windows: draft.windows,
                decisionDeadline: draft.decisionDeadline || null,
                areaLabel: draft.areaLabel || DEFAULT_AREA.label,
                organizerId: auth.uid,
                memberIds: [auth.uid],
                respondedIds: [],
                inviteCode: makeInviteCode(),
                status: "collecting",
                confirmedOptionId: null,
            });
        }).then(function createdACB(meetupId) {
            // Seed the organiser's own participant record from their defaults,
            // so they do not retype what the profile already knows.
            return writeParticipant(meetupId, auth.uid, {
                displayName: auth.displayName,
                role: "organizer",
                startingArea: auth.defaults.startingArea || "",
                startingCoords: auth.defaults.startingCoords || null,
                maxTravelMinutes: auth.defaults.maxTravelMinutes ?? 35,
                needs: auth.defaults.needs || [],
            }).then(function loggedACB() {
                return appendActivity(meetupId, {
                    type: "created",
                    actorId: auth.uid,
                    actorName: auth.displayName,
                    summary: `${auth.displayName} created this Catch Up`,
                });
            }).then(function doneACB() {
                api.dispatch(toastShown({ text: "Catch Up created", tone: "ok" }));
                if (action.payload?.navigateACB) {
                    action.payload.navigateACB(meetupId);
                }
                return meetupId;
            });
        }).catch(function ignoreACB() { /* status already in the store */ });
    },
});

on({
    actionCreator: intent.meetupJoinRequested,
    effect: function joinEffectACB(action, api) {
        const auth = api.getState().auth;
        if (!auth.uid) {
            return undefined;
        }
        return track(api.dispatch, "join", function workACB() {
            return findMeetupByInviteCode(action.payload.code);
        }).then(function foundACB(meetup) {
            return joinMeetup(meetup.id, auth.uid)
                .then(function joinedACB() {
                    return writeParticipant(meetup.id, auth.uid, {
                        displayName: auth.displayName,
                        role: "member",
                        startingArea: auth.defaults.startingArea || "",
                        startingCoords: auth.defaults.startingCoords || null,
                        maxTravelMinutes: auth.defaults.maxTravelMinutes ?? 35,
                        needs: auth.defaults.needs || [],
                    });
                })
                .then(function loggedACB() {
                    return appendActivity(meetup.id, {
                        type: "joined",
                        actorId: auth.uid,
                        actorName: auth.displayName,
                        summary: `${auth.displayName} joined`,
                    });
                })
                .then(function doneACB() {
                    api.dispatch(toastShown({ text: `Joined "${meetup.title}"`, tone: "ok" }));
                    if (action.payload?.navigateACB) {
                        action.payload.navigateACB(meetup.id);
                    }
                });
        }).catch(function ignoreACB() { /* status already in the store */ });
    },
});

// --- my own preferences and availability -----------------------------------

on({
    actionCreator: intent.startingAreaSubmitted,
    effect: function geocodeEffectACB(action, api) {
        return track(api.dispatch, "geocode", function workACB() {
            return geocodeArea(action.payload.label);
        }).then(function gotACB(place) {
            api.dispatch(intent.preferencesSubmitted({
                startingArea: place.label,
                startingCoords: { lat: place.lat, lon: place.lon },
                startingAreaDisplayName: place.displayName,
            }));
        }).catch(function ignoreACB() { /* status already in the store */ });
    },
});

on({
    actionCreator: intent.preferencesSubmitted,
    effect: function preferencesEffectACB(action, api) {
        const state = api.getState();
        const uid = state.auth.uid;
        const meetupId = state.meetup.currentId;
        api.dispatch(myPreferencesChanged({ uid, changes: action.payload }));

        // Preferences a user sets inside a meeting also become their defaults,
        // which is what stops them retyping the same answers next time.
        api.dispatch(defaultsChanged(action.payload));
        if (uid) {
            writeDefaults(uid, api.getState().auth.defaults).catch(function ignoreACB() {});
        }

        if (!uid || !meetupId) {
            return undefined;
        }
        return track(api.dispatch, "savePreferences", function workACB() {
            return writeParticipant(meetupId, uid, {
                displayName: state.auth.displayName,
                ...action.payload,
            });
        }).catch(function ignoreACB() {});
    },
});

on({
    actionCreator: intent.availabilitySubmitted,
    effect: function availabilityEffectACB(action, api) {
        const state = api.getState();
        const uid = state.auth.uid;
        const meetupId = state.meetup.currentId;

        // The view toggles one window at a time; the resulting interval list is
        // computed here from the current state rather than in the presenter.
        const current = state.meetup.availability[uid]?.intervals || [];
        let intervals = action.payload.intervals;
        if (!intervals && action.payload.window) {
            const window = action.payload.window;
            const already = current.some(function matchACB(interval) {
                return interval.start === window.start;
            });
            intervals = already
                ? current.filter(function dropACB(interval) { return interval.start !== window.start; })
                : [...current, { start: window.start, end: window.end }];
        }
        intervals = intervals || [];

        api.dispatch(myAvailabilityChanged({ uid, intervals }));
        if (!uid || !meetupId) {
            return undefined;
        }
        return track(api.dispatch, "saveAvailability", function workACB() {
            return writeAvailability(meetupId, uid, intervals);
        }).then(function markRespondedACB() {
            const responded = state.meetup.meetup?.respondedIds || [];
            if (!responded.includes(uid)) {
                return updateMeetup(meetupId, { respondedIds: [...responded, uid] });
            }
            return undefined;
        }).then(function toastACB() {
            api.dispatch(toastShown({ text: "Availability saved", tone: "ok" }));
        }).catch(function ignoreACB() {});
    },
});

// --- the mash-up: build candidate options ----------------------------------

// One space becomes one option per candidate window. Travel times and weather
// are fetched per option and cached into Firestore, so the whole group sees
// the same numbers and a later reader does not refetch.
function buildOptionsFor(api, meetupId) {
    const state = api.getState();
    const meetup = state.meetup.meetup;
    const participants = Object.values(state.meetup.participants);

    const startingPoints = {};
    participants.forEach(function collectACB(participant) {
        if (participant.startingCoords) {
            startingPoints[participant.uid] = participant.startingCoords;
        }
    });

    const windows = meetup?.windows || [];
    if (windows.length === 0) {
        return Promise.reject(new Error("Add at least one possible day before searching for spaces"));
    }

    // Search around the GROUP, not around a fixed point in the city. Moving
    // one person's starting area moves the centre, which is the whole premise.
    const area = groupArea(participants, DEFAULT_AREA);
    const purpose = meetup?.purpose || "meeting";

    if (area.basedOn === "fallback") {
        throw new Error(
            "Nobody has entered a starting area yet, so there is no group to search around. " +
            "Add a starting area under Availability first.",
        );
    }

    return searchSpaces(area, purpose).then(function gotSpacesACB(spaces) {
        // Shortlist by distance from the group and by category, so one
        // plentiful category cannot fill every slot.
        const shortlist = shortlistSpaces(spaces, area, purpose, 8);
        if (shortlist.length === 0) {
            throw new Error(
                `No suitable spaces found within ${Math.round(area.radiusMetres / 1000)} km ` +
                "of the group. Try a different purpose, or add a space manually.",
            );
        }

        const jobs = [];
        shortlist.forEach(function perSpaceACB(space) {
            windows.forEach(function perWindowACB(window) {
                jobs.push({ space, window });
            });
        });

        let done = 0;
        api.dispatch(requestProgressed({
            key: "options", done, total: jobs.length, label: "Collecting travel times",
        }));

        // Sequential-ish batching keeps us inside the public APIs' rate
        // limits, and reports progress as it goes so the user sees movement.
        return jobs.reduce(function chainACB(previous, job) {
            return previous.then(function nextACB() {
                const optionId = `${job.space.id.replace(/\//g, "_")}__${job.window.start}`;
                return Promise.all([
                    fetchTravelTimes(startingPoints, job.space),
                    fetchWeatherAt(job.space, job.window.start).catch(function noWeatherACB() {
                        return null;
                    }),
                ]).then(function gotDataACB(results) {
                    return writeOption(meetupId, optionId, {
                        id: optionId,
                        space: job.space,
                        window: job.window,
                        travel: results[0],
                        weather: results[1],
                        fetchedAt: Date.now(),
                    });
                }).then(function progressACB() {
                    done += 1;
                    api.dispatch(requestProgressed({
                        key: "options",
                        done,
                        total: jobs.length,
                        label: `Collecting travel times and weather`,
                    }));
                });
            });
        }, Promise.resolve());
    });
}

on({
    actionCreator: intent.optionsRequested,
    effect: function optionsEffectACB(action, api) {
        const state = api.getState();
        const meetupId = state.meetup.currentId;
        const auth = state.auth;
        if (!meetupId) {
            return undefined;
        }

        return track(api.dispatch, "options", function workACB() {
            return clearOptions(meetupId).then(function clearedACB() {
                return buildOptionsFor(api, meetupId);
            });
        }).then(function loggedACB() {
            return appendActivity(meetupId, {
                type: "optionsBuilt",
                actorId: auth.uid,
                actorName: auth.displayName,
                summary: `${auth.displayName} refreshed the options`,
            });
        }).then(function toastACB() {
            api.dispatch(toastShown({ text: "Options updated", tone: "ok" }));
        }).catch(function ignoreACB() {});
    },
});

// Retry for a single option, so one failing space does not force a full
// rebuild. This is what the per-card Retry button dispatches.
on({
    actionCreator: intent.optionRefreshRequested,
    effect: function refreshOneEffectACB(action, api) {
        const state = api.getState();
        const meetupId = state.meetup.currentId;
        const option = state.meetup.options[action.payload.optionId];
        if (!meetupId || !option) {
            return undefined;
        }

        const startingPoints = {};
        Object.values(state.meetup.participants).forEach(function collectACB(participant) {
            if (participant.startingCoords) {
                startingPoints[participant.uid] = participant.startingCoords;
            }
        });

        return track(api.dispatch, `option:${option.id}`, function workACB() {
            return Promise.all([
                fetchTravelTimes(startingPoints, option.space),
                fetchWeatherAt(option.space, option.window.start).catch(function noWeatherACB() {
                    return null;
                }),
            ]).then(function gotACB(results) {
                return writeOption(meetupId, option.id, {
                    travel: results[0],
                    weather: results[1],
                    fetchedAt: Date.now(),
                });
            });
        }).catch(function ignoreACB() {});
    },
});

// --- voting and confirming --------------------------------------------------

on({
    actionCreator: intent.voteCast,
    effect: function voteEffectACB(action, api) {
        const state = api.getState();
        const uid = state.auth.uid;
        const meetupId = state.meetup.currentId;
        if (!uid || !meetupId) {
            return undefined;
        }
        const current = state.meetup.votes[uid]?.optionIds || [];
        const optionId = action.payload.optionId;
        const next = current.includes(optionId)
            ? current.filter(function dropACB(id) { return id !== optionId; })
            : [...current, optionId];

        api.dispatch(myVoteChanged({ uid, optionIds: next }));
        return track(api.dispatch, "saveVote", function workACB() {
            return writeVote(meetupId, uid, next);
        }).then(function loggedACB() {
            return appendActivity(meetupId, {
                type: "voted",
                actorId: uid,
                actorName: state.auth.displayName,
                summary: next.length
                    ? `${state.auth.displayName} voted`
                    : `${state.auth.displayName} withdrew their vote`,
            });
        }).catch(function ignoreACB() {});
    },
});

on({
    actionCreator: intent.votingOpened,
    effect: function openVotingEffectACB(action, api) {
        const meetupId = api.getState().meetup.currentId;
        if (!meetupId) {
            return undefined;
        }
        return track(api.dispatch, "status", function workACB() {
            return updateMeetup(meetupId, { status: "voting" });
        }).catch(function ignoreACB() {});
    },
});

on({
    actionCreator: intent.decisionConfirmed,
    effect: function confirmEffectACB(action, api) {
        const state = api.getState();
        const meetupId = state.meetup.currentId;
        const optionId = action.payload.optionId;
        if (!meetupId || !optionId) {
            return undefined;
        }
        return track(api.dispatch, "status", function workACB() {
            return updateMeetup(meetupId, { status: "confirmed", confirmedOptionId: optionId });
        }).then(function loggedACB() {
            api.dispatch(optionSelected(optionId));
            return appendActivity(meetupId, {
                type: "confirmed",
                actorId: state.auth.uid,
                actorName: state.auth.displayName,
                summary: `${state.auth.displayName} confirmed the plan`,
            });
        }).then(function toastACB() {
            api.dispatch(toastShown({ text: "Plan confirmed for everyone", tone: "ok" }));
        }).catch(function ignoreACB() {});
    },
});

on({
    actionCreator: intent.decisionReopened,
    effect: function reopenEffectACB(action, api) {
        const state = api.getState();
        const meetupId = state.meetup.currentId;
        if (!meetupId) {
            return undefined;
        }
        return track(api.dispatch, "status", function workACB() {
            return updateMeetup(meetupId, { status: "voting", confirmedOptionId: null });
        }).then(function loggedACB() {
            return appendActivity(meetupId, {
                type: "reopened",
                actorId: state.auth.uid,
                actorName: state.auth.displayName,
                summary: `${state.auth.displayName} reopened the decision`,
            });
        }).catch(function ignoreACB() {});
    },
});

// --- calendar export -------------------------------------------------------

function icsTimestamp(value) {
    return new Date(value).toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
}

// Writing a file to disk is a side effect, so it lives here rather than in the
// presenter that offered the button.
on({
    actionCreator: intent.calendarExportRequested,
    effect: function calendarEffectACB(action, api) {
        const state = api.getState();
        const option = state.meetup.options[action.payload.optionId];
        const meetup = state.meetup.meetup;
        if (!option || !meetup) {
            return undefined;
        }

        const lines = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//Catch Up//DH2642//EN",
            "BEGIN:VEVENT",
            `UID:${option.id}@catchup`,
            `DTSTAMP:${icsTimestamp(Date.now())}`,
            `DTSTART:${icsTimestamp(option.window.start)}`,
            `DTEND:${icsTimestamp(option.window.end)}`,
            `SUMMARY:${meetup.title}`,
            `LOCATION:${option.space.name}${option.space.address ? `, ${option.space.address}` : ""}`,
            `DESCRIPTION:Agreed with Catch Up!`,
            "END:VEVENT",
            "END:VCALENDAR",
        ];

        const blob = new Blob([lines.join("\r\n")], { type: "text/calendar" });
        const url = URL.createObjectURL(blob);
        const anchor = document.createElement("a");
        anchor.href = url;
        anchor.download = `${meetup.title.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}.ics`;
        anchor.click();
        URL.revokeObjectURL(url);

        api.dispatch(toastShown({ text: "Calendar file downloaded", tone: "ok" }));
        return undefined;
    },
});
