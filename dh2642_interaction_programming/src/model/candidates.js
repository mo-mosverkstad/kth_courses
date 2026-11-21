// Deciding WHERE to look for spaces, and WHICH of the results to keep.
//
// Pure functions, so both decisions are testable and neither depends on a
// network call. This module exists because getting either one wrong produces
// the same symptom: the same handful of places every time, no matter what the
// group actually entered.
import { centroid, distanceKm, spreadKm } from "/src/geo.js";

// How far outside the group's own spread we are willing to look.
const MARGIN_KM = 1.5;
const MIN_RADIUS_KM = 1.2;
const MAX_RADIUS_KM = 12;

// Where to centre the search.
//
// The centre is the group's centroid, not a fixed point in the city. This is
// the whole premise of the app: a space is being chosen for these particular
// people, so moving one person's starting area must move the search.
export function groupArea(participants, fallback) {
    const points = (participants || [])
        .map(function coordsACB(participant) { return participant.startingCoords; })
        .filter(Boolean);

    if (points.length === 0) {
        return {
            ...fallback,
            basedOn: "fallback",
            memberCount: 0,
        };
    }

    const centre = centroid(points);
    const spread = spreadKm(centre, points);

    // A tight group gets a small radius; a scattered one gets a wider search,
    // but never so wide that it drifts into a different part of the country.
    const radiusKm = Math.min(
        MAX_RADIUS_KM,
        Math.max(MIN_RADIUS_KM, spread + MARGIN_KM),
    );

    return {
        label: points.length === 1
            ? "Near the one starting area entered"
            : `Between the ${points.length} starting areas entered`,
        lat: centre.lat,
        lon: centre.lon,
        radiusMetres: Math.round(radiusKm * 1000),
        basedOn: "participants",
        memberCount: points.length,
        spreadKm: spread,
    };
}

// Which categories suit which purpose, and how many of each we are willing to
// shortlist. The caps are what stop one plentiful category - cafes, always -
// from filling every slot and hiding the libraries.
const CATEGORY_PLAN = {
    meeting: [
        { categories: ["library"], max: 3 },
        { categories: ["coworking_space"], max: 2 },
        { categories: ["cafe"], max: 3 },
    ],
    study: [
        { categories: ["library"], max: 4 },
        { categories: ["coworking_space"], max: 2 },
        { categories: ["cafe"], max: 2 },
    ],
    social: [
        { categories: ["cafe"], max: 4 },
        { categories: ["restaurant"], max: 2 },
        { categories: ["pub"], max: 2 },
    ],
};

function hasName(space) {
    return Boolean(space.name) && space.name !== "Unnamed space";
}

// Shortlist the spaces we will actually spend API calls on.
//
// Sorted by distance from the group's centre, then filled category by category
// against the plan above. Taking Overpass's own ordering instead - which is by
// element type and id - is what produced the same list every time.
// Below this a list is too short to be a comparison at all, so the caps are
// relaxed rather than handing the group one option.
const MIN_USEFUL = 3;

export function shortlistSpaces(spaces, area, purpose, limit) {
    const plan = CATEGORY_PLAN[purpose] || CATEGORY_PLAN.meeting;
    const total = limit || 8;

    const byDistance = (spaces || [])
        .filter(hasName)
        .map(function withDistanceACB(space) {
            return { ...space, distanceKm: distanceKm(area, space) };
        })
        .sort(function nearestACB(a, b) {
            return a.distanceKm - b.distanceKm;
        });

    const chosen = [];
    const taken = new Set();
    const usedPerCategory = {};

    function capFor(category) {
        const slot = plan.find(function matchACB(entry) {
            return entry.categories.includes(category);
        });
        // A category the plan does not mention has no cap: it is not the one
        // at risk of swamping the list.
        return slot ? slot.max : Infinity;
    }

    function takeACB(space) {
        chosen.push(space);
        taken.add(space.id);
        usedPerCategory[space.category] = (usedPerCategory[space.category] || 0) + 1;
    }

    // Pass 1: fill the plan, nearest first within each category.
    plan.forEach(function fillACB(slot) {
        byDistance.forEach(function considerACB(space) {
            const used = usedPerCategory[space.category] || 0;
            if (taken.has(space.id) || used >= slot.max) {
                return;
            }
            if (slot.categories.includes(space.category)) {
                takeACB(space);
            }
        });
    });

    // Pass 2: top up only with categories that are still under their cap, or
    // that the plan does not mention at all. A category already at its cap is
    // deliberately NOT topped up: eight cafes are not eight decisions, and
    // padding the list with them is what made every search look identical.
    byDistance.forEach(function topUpACB(space) {
        if (chosen.length >= total || taken.has(space.id)) {
            return;
        }
        if ((usedPerCategory[space.category] || 0) < capFor(space.category)) {
            takeACB(space);
        }
    });

    // Pass 3: only if the result is too small to compare, ignore the caps.
    if (chosen.length < MIN_USEFUL) {
        byDistance.forEach(function relaxACB(space) {
            if (chosen.length < Math.min(total, MIN_USEFUL) && !taken.has(space.id)) {
                takeACB(space);
            }
        });
    }

    return chosen
        .sort(function nearestACB(a, b) { return a.distanceKm - b.distanceKm; })
        .slice(0, total);
}
