// External source module: weather forecast at a proposed meeting time.
// Open-Meteo needs no key and is reachable from the browser.
import { OPEN_METEO_URL } from "/src/apiConfig.js";

function nearestHourIndex(times, target) {
    const wanted = new Date(target).getTime();
    let best = -1;
    let bestDistance = Infinity;
    times.forEach(function compareACB(iso, index) {
        const distance = Math.abs(new Date(iso).getTime() - wanted);
        if (distance < bestDistance) {
            bestDistance = distance;
            best = index;
        }
    });
    // Open-Meteo only forecasts about 16 days ahead. Beyond that there is no
    // nearby hour and we report no data rather than a misleading number.
    return bestDistance <= 1000 * 60 * 60 * 6 ? best : -1;
}

export function fetchWeatherAt(space, isoDateTime) {
    const params = new URLSearchParams({
        latitude: String(space.lat),
        longitude: String(space.lon),
        hourly: "temperature_2m,precipitation_probability,wind_speed_10m",
        timezone: "Europe/Stockholm",
        forecast_days: "16",
    });

    return fetch(`${OPEN_METEO_URL}?${params}`)
        .then(gotResponseACB)
        .then(gotForecastACB);

    function gotResponseACB(response) {
        if (!response.ok) {
            throw new Error(`Open-Meteo request failed with status ${response.status}`);
        }
        return response.json();
    }

    function gotForecastACB(data) {
        const hourly = data.hourly || {};
        const times = hourly.time || [];
        const index = nearestHourIndex(times, isoDateTime);
        if (index < 0) {
            return null;
        }
        return {
            time: times[index],
            temperatureC: hourly.temperature_2m?.[index] ?? null,
            precipitationPercent: hourly.precipitation_probability?.[index] ?? null,
            windSpeed: hourly.wind_speed_10m?.[index] ?? null,
            source: "Open-Meteo",
        };
    }
}
