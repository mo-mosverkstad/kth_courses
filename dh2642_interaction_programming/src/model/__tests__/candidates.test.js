import { describe, expect, it } from "vitest";
import { groupArea, shortlistSpaces } from "../candidates.js";
import { distanceKm } from "/src/geo.js";

const FALLBACK = {
    label: "Central Stockholm and KTH campuses",
    lat: 59.3426,
    lon: 18.0527,
    radiusMetres: 6000,
};

// Roughly: Odenplan, Kista, Flemingsberg.
const ODENPLAN = { lat: 59.3429, lon: 18.0496 };
const KISTA = { lat: 59.4033, lon: 17.9450 };
const FLEMINGSBERG = { lat: 59.2195, lon: 17.9430 };

function member(name, coords) {
    return { uid: name, displayName: name, startingCoords: coords };
}

describe("groupArea", () => {
    it("centres on the group, not on a fixed point in the city", () => {
        const area = groupArea([member("a", KISTA), member("b", KISTA)], FALLBACK);
        expect(area.basedOn).toBe("participants");
        // The centre must be at Kista, nowhere near the hardcoded fallback.
        expect(distanceKm(area, KISTA)).toBeLessThan(0.1);
        expect(distanceKm(area, FALLBACK)).toBeGreaterThan(5);
    });

    it("moves when a member's starting area moves", () => {
        const before = groupArea([member("a", ODENPLAN), member("b", ODENPLAN)], FALLBACK);
        const after = groupArea([member("a", ODENPLAN), member("b", FLEMINGSBERG)], FALLBACK);
        // This is the regression that mattered: editing a starting area used to
        // change nothing at all about where we searched.
        expect(distanceKm(before, after)).toBeGreaterThan(3);
    });

    it("widens the radius for a scattered group and keeps it tight for a close one", () => {
        const tight = groupArea([member("a", ODENPLAN), member("b", ODENPLAN)], FALLBACK);
        const spread = groupArea(
            [member("a", ODENPLAN), member("b", KISTA), member("c", FLEMINGSBERG)],
            FALLBACK,
        );
        expect(spread.radiusMetres).toBeGreaterThan(tight.radiusMetres);
    });

    it("never searches an absurdly large radius", () => {
        const far = groupArea(
            [member("a", { lat: 55.6, lon: 13.0 }), member("b", { lat: 63.8, lon: 20.3 })],
            FALLBACK,
        );
        expect(far.radiusMetres).toBeLessThanOrEqual(12000);
    });

    it("reports a fallback when nobody entered a starting area", () => {
        expect(groupArea([{ uid: "a", displayName: "a" }], FALLBACK).basedOn).toBe("fallback");
        expect(groupArea([], FALLBACK).basedOn).toBe("fallback");
    });
});

describe("shortlistSpaces", () => {
    function space(id, category, coords, name) {
        return { id, category, name: name || `${category}-${id}`, ...coords };
    }

    // Twelve cafes close in, two libraries slightly further out: the exact
    // shape that produced an all-cafe list before.
    function mixedPool() {
        const pool = [];
        for (let i = 0; i < 12; i += 1) {
            pool.push(space(`cafe${i}`, "cafe", { lat: 59.3429 + i * 0.0002, lon: 18.0496 }));
        }
        pool.push(space("lib1", "library", { lat: 59.3470, lon: 18.0530 }));
        pool.push(space("lib2", "library", { lat: 59.3480, lon: 18.0540 }));
        pool.push(space("cowork1", "coworking_space", { lat: 59.3500, lon: 18.0560 }));
        return pool;
    }

    it("does not let cafes fill every slot", () => {
        const area = groupArea([member("a", ODENPLAN)], FALLBACK);
        const chosen = shortlistSpaces(mixedPool(), area, "meeting", 8);
        const cafes = chosen.filter(function cafeACB(s) { return s.category === "cafe"; });
        expect(cafes.length).toBeLessThanOrEqual(3);
        expect(chosen.some(function libACB(s) { return s.category === "library"; })).toBe(true);
    });

    it("prefers libraries for a study session", () => {
        const area = groupArea([member("a", ODENPLAN)], FALLBACK);
        const chosen = shortlistSpaces(mixedPool(), area, "study", 8);
        const libraries = chosen.filter(function libACB(s) { return s.category === "library"; });
        const cafes = chosen.filter(function cafeACB(s) { return s.category === "cafe"; });
        expect(libraries.length).toBeGreaterThan(0);
        expect(cafes.length).toBeLessThanOrEqual(2);
    });

    it("returns the nearest spaces to the group, not an arbitrary slice", () => {
        const near = space("near", "cafe", { lat: 59.3429, lon: 18.0496 });
        const far = space("far", "cafe", { lat: 59.4500, lon: 18.3000 });
        const area = groupArea([member("a", ODENPLAN)], FALLBACK);
        // "far" is first in the input, as Overpass ordering would have it.
        const chosen = shortlistSpaces([far, near], area, "meeting", 1);
        expect(chosen[0].id).toBe("near");
    });

    it("drops unnamed spaces", () => {
        const area = groupArea([member("a", ODENPLAN)], FALLBACK);
        const pool = [space("x", "cafe", ODENPLAN, "Unnamed space"), space("y", "cafe", ODENPLAN, "Real Cafe")];
        const chosen = shortlistSpaces(pool, area, "meeting", 8);
        expect(chosen.map(function idACB(s) { return s.id; })).toEqual(["y"]);
    });

    it("returns a short honest list rather than padding with a capped category", () => {
        const area = groupArea([member("a", ODENPLAN)], FALLBACK);
        const onlyCafes = [];
        for (let i = 0; i < 10; i += 1) {
            onlyCafes.push(space(`c${i}`, "cafe", { lat: 59.3429 + i * 0.0003, lon: 18.0496 }));
        }
        // Ten cafes available, limit 6, but the cafe cap for a meeting is 3.
        // Three real choices beat six near-identical ones.
        const chosen = shortlistSpaces(onlyCafes, area, "meeting", 6);
        expect(chosen).toHaveLength(3);
    });

    it("relaxes the caps rather than returning fewer than three options", () => {
        const area = groupArea([member("a", ODENPLAN)], FALLBACK);
        const twoCafes = [
            space("c1", "cafe", ODENPLAN),
            space("c2", "cafe", { lat: 59.3431, lon: 18.0498 }),
        ];
        expect(shortlistSpaces(twoCafes, area, "meeting", 8)).toHaveLength(2);
    });

    it("counts unmentioned categories as uncapped, so they can top up the list", () => {
        const area = groupArea([member("a", ODENPLAN)], FALLBACK);
        const pool = [
            space("c1", "cafe", ODENPLAN),
            space("c2", "cafe", { lat: 59.3431, lon: 18.0498 }),
            space("c3", "cafe", { lat: 59.3433, lon: 18.0500 }),
            space("c4", "cafe", { lat: 59.3435, lon: 18.0502 }),
            space("m1", "museum", { lat: 59.3437, lon: 18.0504 }),
            space("m2", "museum", { lat: 59.3439, lon: 18.0506 }),
        ];
        const chosen = shortlistSpaces(pool, area, "meeting", 8);
        const cafes = chosen.filter(function cafeACB(s) { return s.category === "cafe"; });
        expect(cafes.length).toBe(3);
        expect(chosen.filter(function mACB(s) { return s.category === "museum"; })).toHaveLength(2);
    });

    it("never returns the same space twice", () => {
        const area = groupArea([member("a", ODENPLAN)], FALLBACK);
        const chosen = shortlistSpaces(mixedPool(), area, "meeting", 8);
        const ids = chosen.map(function idACB(s) { return s.id; });
        expect(new Set(ids).size).toBe(ids.length);
    });
});
