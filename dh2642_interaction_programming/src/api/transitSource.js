// External source module: public transport travel time per participant.
//
// Primary source is Trafiklab Resrobot. Because that needs a registered key
// and may be blocked from the browser, this module degrades instead of
// failing: without a usable key it returns a distance-based estimate flagged
// with estimated:true, and the interface labels those numbers as estimates.
import { RESROBOT_KEY, RESROBOT_URL } from "/src/apiConfig.js";
import { distanceKm } from "/src/geo.js";

// Rough door-to-door speed including waiting and walking, in km/h. Only used
// for the fallback estimate.
const ASSUMED_SPEED_KMH = 18;
const FIXED_OVERHEAD_MIN = 6;

export function estimateMinutes(from, to) {
    const km = distanceKm(from, to);
    return Math.max(2, Math.round(FIXED_OVERHEAD_MIN + (km / ASSUMED_SPEED_KMH) * 60));
}

function hasKey() {
    return typeof RESROBOT_KEY === "string" && RESROBOT_KEY.trim().length > 0;
}

function parseDuration(trip) {
    // Resrobot reports a duration as an ISO-8601 period such as PT1H05M.
    const match = /PT(?:(\d+)H)?(?:(\d+)M)?/.exec(trip.duration || "");
    if (match) {
        const hours = Number(match[1] || 0);
        const minutes = Number(match[2] || 0);
        if (hours || minutes) {
            return hours * 60 + minutes;
        }
    }
    const legs = trip.LegList?.Leg || [];
    return legs.length ? legs.length * 10 : null;
}

function requestResrobotTrip(from, to) {
    const params = new URLSearchParams({
        format: "json",
        accessId: RESROBOT_KEY,
        originCoordLat: String(from.lat),
        originCoordLong: String(from.lon),
        destCoordLat: String(to.lat),
        destCoordLong: String(to.lon),
        numB: "0",
        numF: "1",
    });

    return fetch(`${RESROBOT_URL}/trip?${params}`)
        .then(gotResponseACB)
        .then(gotTripACB);

    function gotResponseACB(response) {
        if (!response.ok) {
            throw new Error(`Resrobot request failed with status ${response.status}`);
        }
        return response.json();
    }

    function gotTripACB(data) {
        const trip = (data.Trip || [])[0];
        const minutes = trip ? parseDuration(trip) : null;
        if (!minutes) {
            throw new Error("Resrobot returned no usable trip");
        }
        const legs = (trip.LegList?.Leg || []).map(function legACB(leg) {
            return {
                mode: leg.type === "WALK" ? "walk" : (leg.Product?.[0]?.catOutL || "transit"),
                name: leg.name || null,
                from: leg.Origin?.name || null,
                to: leg.Destination?.name || null,
            };
        });
        return { minutes, legs, estimated: false, source: "Trafiklab Resrobot" };
    }
}

// Travel time from one starting point to one space.
export function fetchTravelTime(from, to) {
    function fallbackACB() {
        return {
            minutes: estimateMinutes(from, to),
            legs: [],
            estimated: true,
            source: "Estimated from distance",
        };
    }

    if (!hasKey()) {
        return Promise.resolve(fallbackACB());
    }
    return requestResrobotTrip(from, to).catch(fallbackACB);
}

// Travel time for every participant to one space, keyed by user id.
// Resolves even when individual requests fail, so one bad journey does not
// discard the whole option.
export function fetchTravelTimes(startingPoints, space) {
    const uids = Object.keys(startingPoints);
    const requests = uids.map(function oneTravelACB(uid) {
        return fetchTravelTime(startingPoints[uid], space)
            .then(function labelACB(result) {
                return [uid, result];
            });
    });

    return Promise.all(requests).then(function collectACB(entries) {
        return Object.fromEntries(entries);
    });
}
