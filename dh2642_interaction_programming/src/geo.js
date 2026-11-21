// Pure geographic helpers.
//
// Top-level like apiConfig.js, so both api/ and model/ can use them without
// either importing the other and breaking the layer boundaries.

const EARTH_RADIUS_KM = 6371;

function toRadians(degrees) {
    return (degrees * Math.PI) / 180;
}

export function distanceKm(from, to) {
    const dLat = toRadians(to.lat - from.lat);
    const dLon = toRadians(to.lon - from.lon);
    const a = Math.sin(dLat / 2) ** 2 +
              Math.cos(toRadians(from.lat)) * Math.cos(toRadians(to.lat)) *
              Math.sin(dLon / 2) ** 2;
    return 2 * EARTH_RADIUS_KM * Math.asin(Math.min(1, Math.sqrt(a)));
}

// Average position of a set of points. Good enough at city scale: over a few
// tens of kilometres the error against a proper spherical mean is metres.
export function centroid(points) {
    const usable = (points || []).filter(function validACB(point) {
        return point && typeof point.lat === "number" && typeof point.lon === "number";
    });
    if (usable.length === 0) {
        return null;
    }
    const sum = usable.reduce(function addACB(total, point) {
        return { lat: total.lat + point.lat, lon: total.lon + point.lon };
    }, { lat: 0, lon: 0 });
    return { lat: sum.lat / usable.length, lon: sum.lon / usable.length };
}

// Largest distance from a centre to any of the points, in kilometres.
export function spreadKm(centre, points) {
    if (!centre || !points || points.length === 0) {
        return 0;
    }
    return Math.max(...points.map(function distACB(point) {
        return distanceKm(centre, point);
    }));
}
