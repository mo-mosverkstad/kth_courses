import { describe, expect, it } from "vitest";
import { travelRowsFor } from "../selectors.js";

describe("travelRowsFor", () => {
    const participants = [
        { uid: "a", displayName: "Mia", maxTravelMinutes: 35 },
        { uid: "b", displayName: "Sam", maxTravelMinutes: 20 },
    ];

    it("produces one row per participant, never a single average", () => {
        const option = { travel: { a: { minutes: 12 }, b: { minutes: 30 } } };
        const rows = travelRowsFor(option, participants);
        expect(rows).toHaveLength(2);
        expect(rows.map(function nameACB(r) { return r.name; })).toEqual(["Mia", "Sam"]);
    });

    it("carries each person's own limit so an unfair journey can be marked", () => {
        const option = { travel: { a: { minutes: 12 }, b: { minutes: 30 } } };
        const rows = travelRowsFor(option, participants);
        expect(rows[1].minutes).toBeGreaterThan(rows[1].limit);
    });

    it("reports a missing journey as null rather than zero", () => {
        const rows = travelRowsFor({ travel: { a: { minutes: 12 } } }, participants);
        expect(rows[1].minutes).toBeNull();
    });
});
