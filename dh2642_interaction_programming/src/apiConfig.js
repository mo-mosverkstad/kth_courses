// Endpoints and keys for the external data sources.
//
// Only Resrobot needs a key. Register a free one at https://www.trafiklab.se
// and paste it below. The application works without it: transitSource falls
// back to a distance-based estimate and marks every affected number as
// estimated in the interface, so a missing key degrades the data rather than
// breaking the app.
export const RESROBOT_KEY = "";

export const RESROBOT_URL = "https://api.resrobot.se/v2.1";
export const OVERPASS_URL = "https://overpass-api.de/api/interpreter";
export const NOMINATIM_URL = "https://nominatim.openstreetmap.org";
export const OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast";

// Raster tiles for the map. OpenStreetMap's own tiles are only acceptable for
// low-volume development use; swap this for a provider with a suitable licence
// before any real deployment.
export const MAP_TILE_URL = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
export const MAP_TILE_ATTRIBUTION = "(c) OpenStreetMap contributors";

// The search area is deliberately bounded, which keeps the candidate set small
// and the Overpass query fast.
export const DEFAULT_AREA = {
    label: "Central Stockholm and KTH campuses",
    lat: 59.3426,
    lon: 18.0527,
    radiusMetres: 6000,
};
