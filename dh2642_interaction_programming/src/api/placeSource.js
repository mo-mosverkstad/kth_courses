// External source module: candidate meeting spaces and geocoding.
//
// Overpass  - discovers spaces inside the search area
// Nominatim - turns a typed starting area such as "Odenplan" into coordinates
//
// This module knows nothing about the store, Firebase or the views. It only
// fetches and normalises into our own internal shape.
import {
    GEOCODE_COUNTRY_CODES, GEOCODE_VIEWBOX, NOMINATIM_URL, OVERPASS_URL,
} from "/src/apiConfig.js";

// Which OpenStreetMap amenities we consider usable as a meeting space, mapped
// to the purpose that suggests them.
const SPACE_FILTERS = {
    meeting: ['amenity=library', 'amenity=coworking_space', 'amenity=cafe'],
    study: ['amenity=library', 'amenity=coworking_space'],
    social: ['amenity=cafe', 'amenity=restaurant', 'amenity=pub'],
};

function buildOverpassQuery(area, purpose) {
    const filters = SPACE_FILTERS[purpose] || SPACE_FILTERS.meeting;
    const radius = Math.round(area.radiusMetres);
    const parts = filters.map(function filterToClauseACB(filter) {
        const [key, value] = filter.split("=");
        return `node["${key}"="${value}"](around:${radius},${area.lat},${area.lon});` +
               `way["${key}"="${value}"](around:${radius},${area.lat},${area.lon});`;
    });
    // The cap is generous on purpose: the caller shortlists by distance and by
    // category, so it needs a real pool to choose from. Capping at a handful
    // here would hand back whatever Overpass happened to return first.
    return `[out:json][timeout:25];(${parts.join("")});out center tags 250;`;
}

// OpenStreetMap tags are free text and often missing. We translate the ones we
// understand and report the rest as unknown rather than as absent, because
// "no wheelchair tag" is not the same as "not accessible".
function readFacility(tags, key, truthy) {
    const value = tags[key];
    if (value === undefined) {
        return "unknown";
    }
    return truthy.includes(value) ? "yes" : "no";
}

function normaliseSpace(element) {
    const tags = element.tags || {};
    const centre = element.center || element;
    if (typeof centre.lat !== "number" || typeof centre.lon !== "number") {
        return null;
    }
    return {
        id: `${element.type}/${element.id}`,
        name: tags.name || tags["name:en"] || "Unnamed space",
        category: tags.amenity || "unknown",
        lat: centre.lat,
        lon: centre.lon,
        source: "OpenStreetMap",
        address: [tags["addr:street"], tags["addr:housenumber"]]
            .filter(Boolean).join(" ") || null,
        openingHours: tags.opening_hours || null,
        facilities: {
            stepFree: readFacility(tags, "wheelchair", ["yes", "limited"]),
            wifi: readFacility(tags, "internet_access", ["wlan", "yes", "wired", "terminal"]),
            power: readFacility(tags, "power_supply", ["yes"]),
            food: tags.amenity === "cafe" || tags.amenity === "restaurant" ? "yes" : "unknown",
        },
    };
}

export function searchSpaces(area, purpose) {
    const body = new URLSearchParams({ data: buildOverpassQuery(area, purpose) });

    return fetch(OVERPASS_URL, { method: "POST", body })
        .then(gotResponseACB)
        .then(gotSpacesACB);

    function gotResponseACB(response) {
        if (!response.ok) {
            throw new Error(`Overpass request failed with status ${response.status}`);
        }
        return response.json();
    }

    function gotSpacesACB(data) {
        const elements = data.elements || [];
        const spaces = elements.map(normaliseSpace).filter(Boolean);
        // Overpass returns a node and a way for the same building often enough
        // that de-duplicating by name and rough position is worth it.
        const seen = new Set();
        return spaces.filter(function uniqueACB(space) {
            const key = `${space.name}@${space.lat.toFixed(3)},${space.lon.toFixed(3)}`;
            if (seen.has(key)) {
                return false;
            }
            seen.add(key);
            return true;
        });
    }
}

// Resolve a typed place name to coordinates. Deliberately coarse: we ask for
// the area, not a street address, because starting points are shared with the
// group and must never be a home address.
//
// The country and viewbox bias are not optional. Without them a short query
// matches the wrong continent: "Kista" resolves to Kysta in Slovakia rather
// than Kista in Stockholm, and every travel time computed from it is wrong.
export function geocodeArea(query) {
    const params = new URLSearchParams({
        q: query,
        format: "jsonv2",
        limit: "1",
        addressdetails: "0",
        countrycodes: GEOCODE_COUNTRY_CODES,
        viewbox: GEOCODE_VIEWBOX,
    });

    return fetch(`${NOMINATIM_URL}/search?${params}`, {
        headers: { Accept: "application/json" },
    }).then(gotResponseACB).then(gotPlaceACB);

    function gotResponseACB(response) {
        if (!response.ok) {
            throw new Error(`Nominatim request failed with status ${response.status}`);
        }
        return response.json();
    }

    function gotPlaceACB(results) {
        if (!results || results.length === 0) {
            throw new Error(`Could not find a place called "${query}"`);
        }
        const place = results[0];
        return {
            label: query,
            displayName: place.display_name,
            lat: Number(place.lat),
            lon: Number(place.lon),
            source: "OpenStreetMap / Nominatim",
        };
    }
}
