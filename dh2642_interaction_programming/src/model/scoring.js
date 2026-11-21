// Pure scoring logic. No store, no framework, no I/O - so it is directly
// unit-testable and the explanation shown in the interface is generated from
// the same numbers that produce the ranking.

// Weights are design assumptions to be tested with users, not facts.
export const WEIGHTS = {
    meanTravel: 1,
    maxTravel: 0.7,
    unavailable: 25,
    accessibility: 40,
    openingHours: 15,
    weather: 10,
};

export function travelStats(travelByUid) {
    const entries = Object.values(travelByUid || {});
    const minutes = entries
        .map(function minutesACB(entry) { return entry?.minutes; })
        .filter(function presentACB(value) { return typeof value === "number"; });

    if (minutes.length === 0) {
        return { mean: null, max: null, count: 0, estimated: false };
    }
    const sum = minutes.reduce(function addACB(a, b) { return a + b; }, 0);
    return {
        mean: Math.round(sum / minutes.length),
        max: Math.max(...minutes),
        count: minutes.length,
        estimated: entries.some(function estACB(entry) { return entry?.estimated; }),
    };
}

// How many participants have this window inside one of their intervals.
export function availableCount(availabilityByUid, window) {
    const start = new Date(window.start).getTime();
    const end = new Date(window.end).getTime();
    return Object.values(availabilityByUid || {}).filter(function freeACB(record) {
        return (record?.intervals || []).some(function coversACB(interval) {
            return new Date(interval.start).getTime() <= start &&
                   new Date(interval.end).getTime() >= end;
        });
    }).length;
}

// Participants whose hard requirements this space does not meet. "unknown"
// never counts as satisfied for a hard requirement, because OpenStreetMap not
// having a tag is not evidence that the space is accessible.
export function unmetNeeds(space, participants) {
    const unmet = [];
    (participants || []).forEach(function checkACB(participant) {
        (participant.needs || []).forEach(function needACB(need) {
            const state = space?.facilities?.[need];
            const hard = need === "stepFree";
            if (state === "no" || (hard && state !== "yes")) {
                unmet.push({ uid: participant.uid, name: participant.displayName, need, state: state || "unknown" });
            }
        });
    });
    return unmet;
}

// Very small opening-hours check. OpenStreetMap opening_hours is a rich
// grammar and we only read the simple "closes at HH:MM" case, so anything we
// cannot parse is reported as unknown instead of being guessed at.
export function closesBefore(space, window) {
    if (!space?.openingHours) {
        return "unknown";
    }
    if (/24\/7/.test(space.openingHours)) {
        return "no";
    }
    const times = [...space.openingHours.matchAll(/(\d{1,2}):(\d{2})/g)];
    if (times.length < 2) {
        return "unknown";
    }
    const last = times[times.length - 1];
    const closingMinutes = Number(last[1]) * 60 + Number(last[2]);
    const endDate = new Date(window.end);
    const endMinutes = endDate.getHours() * 60 + endDate.getMinutes();
    return endMinutes > closingMinutes ? "yes" : "no";
}

function weatherPenaltyFor(weather, weights) {
    if (!weather || weather.precipitationPercent === null || weather.precipitationPercent === undefined) {
        return { penalty: 0, note: "no weather data" };
    }
    const chance = weather.precipitationPercent;
    const penalty = (chance / 100) * weights.weather;
    return {
        penalty,
        note: `${chance}% chance of rain at ${new Date(weather.time).toLocaleTimeString("sv-SE", { hour: "2-digit", minute: "2-digit" })}`,
    };
}

// Build the full explanation for one option. Every term that contributes to
// the cost also produces a line the interface can show.
export function explainOption(option, context) {
    const weights = context.weights || WEIGHTS;
    const participants = context.participants || [];
    const stats = travelStats(option.travel);
    const free = availableCount(context.availability, option.window);
    const unavailable = Math.max(0, participants.length - free);
    const unmet = unmetNeeds(option.space, participants);
    const closes = closesBefore(option.space, option.window);
    const weather = weatherPenaltyFor(option.weather, weights);

    const components = [
        {
            key: "meanTravel",
            label: "Average travel time",
            value: stats.mean === null ? "no data" : `${stats.mean} min`,
            penalty: (stats.mean || 0) * weights.meanTravel,
            status: stats.mean === null ? "unknown" : "info",
        },
        {
            key: "maxTravel",
            label: "Longest single journey",
            value: stats.max === null ? "no data" : `${stats.max} min`,
            penalty: (stats.max || 0) * weights.maxTravel,
            status: stats.max === null ? "unknown" : "info",
        },
        {
            key: "availability",
            label: "Participants free in this window",
            value: `${free} of ${participants.length}`,
            penalty: unavailable * weights.unavailable,
            status: unavailable === 0 ? "ok" : "warn",
        },
        {
            key: "accessibility",
            label: "Accessibility requirements",
            value: unmet.length === 0 ? "satisfied" : `${unmet.length} unmet`,
            penalty: unmet.length * weights.accessibility,
            status: unmet.length === 0 ? "ok" : "warn",
        },
        {
            key: "openingHours",
            label: "Open for the whole window",
            value: closes === "no" ? "yes" : (closes === "yes" ? "closes too early" : "hours unknown"),
            penalty: closes === "yes" ? weights.openingHours : 0,
            status: closes === "no" ? "ok" : (closes === "yes" ? "warn" : "unknown"),
        },
        {
            key: "weather",
            label: "Weather",
            value: weather.note,
            penalty: weather.penalty,
            status: weather.penalty > weights.weather / 2 ? "warn" : "info",
        },
    ];

    const cost = components.reduce(function sumACB(total, part) {
        return total + part.penalty;
    }, 0);

    return {
        cost,
        components,
        stats,
        free,
        unmet,
        missingData: stats.count < participants.length || !option.weather,
    };
}

// Rank a set of options. Suitability is scaled against the best and the worst
// candidate in this particular set, so it answers "how does this compare with
// the alternatives we actually found" rather than pretending to be absolute.
export function rankOptions(options, context) {
    const explained = (options || []).map(function explainACB(option) {
        return { ...option, explanation: explainOption(option, context) };
    });

    const costs = explained.map(function costACB(option) { return option.explanation.cost; });
    const best = Math.min(...costs);
    const worst = Math.max(...costs);
    const span = worst - best;

    return explained
        .map(function suitabilityACB(option) {
            const cost = option.explanation.cost;
            const suitability = span === 0 ? 100 : Math.round(100 - ((cost - best) / span) * 45);
            return { ...option, suitability };
        })
        .sort(function byCostACB(a, b) {
            return a.explanation.cost - b.explanation.cost;
        });
}

// Derived "can we decide yet" summary, used by the organiser's readiness panel.
export function decisionReadiness(context) {
    const participants = context.participants || [];
    const responded = participants.filter(function respondedACB(participant) {
        return Boolean(context.availability?.[participant.uid]?.intervals?.length);
    });
    const voted = Object.keys(context.votes || {}).filter(function hasVoteACB(uid) {
        return (context.votes[uid]?.optionIds || []).length > 0;
    });

    const checks = [
        {
            key: "responded",
            label: `${responded.length} of ${participants.length} added availability`,
            ok: participants.length > 0 && responded.length === participants.length,
        },
        {
            key: "options",
            label: `${(context.options || []).length} candidate spaces found`,
            ok: (context.options || []).length > 0,
        },
        {
            key: "votes",
            label: `${voted.length} of ${participants.length} voted`,
            ok: participants.length > 0 && voted.length === participants.length,
        },
    ];

    return { checks, ready: checks.every(function okACB(check) { return check.ok; }) };
}
