import { describe, expect, it } from "vitest";
import {
    availableCount, closesBefore, decisionReadiness, explainOption,
    rankOptions, travelStats, unmetNeeds, WEIGHTS,
} from "../scoring.js";

const WINDOW = { start: "2026-11-24T14:00:00.000Z", end: "2026-11-24T16:00:00.000Z" };

function space(overrides) {
    return {
        id: "node/1",
        name: "KTH Library",
        lat: 59.3478,
        lon: 18.0705,
        openingHours: "Mo-Fr 08:00-20:00",
        facilities: { stepFree: "yes", wifi: "yes", power: "yes", food: "unknown" },
        ...overrides,
    };
}

const PARTICIPANTS = [
    { uid: "a", displayName: "Mia", maxTravelMinutes: 35, needs: [] },
    { uid: "b", displayName: "Noor", maxTravelMinutes: 35, needs: [] },
    { uid: "c", displayName: "Sam", maxTravelMinutes: 35, needs: ["stepFree"] },
];

const ALL_FREE = {
    a: { intervals: [WINDOW] },
    b: { intervals: [WINDOW] },
    c: { intervals: [WINDOW] },
};

describe("travelStats", () => {
    it("reports the mean and the worst journey", () => {
        const stats = travelStats({ a: { minutes: 10 }, b: { minutes: 20 }, c: { minutes: 30 } });
        expect(stats.mean).toBe(20);
        expect(stats.max).toBe(30);
        expect(stats.count).toBe(3);
    });

    it("reports no data rather than zero when nothing is known", () => {
        const stats = travelStats({});
        expect(stats.mean).toBeNull();
        expect(stats.max).toBeNull();
    });

    it("flags the whole option as estimated if any leg was estimated", () => {
        const stats = travelStats({ a: { minutes: 10 }, b: { minutes: 12, estimated: true } });
        expect(stats.estimated).toBe(true);
    });
});

describe("availableCount", () => {
    it("counts only participants whose interval covers the whole window", () => {
        const partly = {
            a: { intervals: [WINDOW] },
            b: { intervals: [{ start: WINDOW.start, end: "2026-11-24T15:00:00.000Z" }] },
        };
        expect(availableCount(partly, WINDOW)).toBe(1);
    });
});

describe("unmetNeeds", () => {
    it("treats a missing accessibility tag as unmet, not as satisfied", () => {
        const unmet = unmetNeeds(space({ facilities: { stepFree: "unknown" } }), PARTICIPANTS);
        expect(unmet).toHaveLength(1);
        expect(unmet[0].need).toBe("stepFree");
        expect(unmet[0].state).toBe("unknown");
    });

    it("is satisfied when the source says yes", () => {
        expect(unmetNeeds(space(), PARTICIPANTS)).toHaveLength(0);
    });
});

describe("closesBefore", () => {
    it("reports unknown when the hours cannot be parsed", () => {
        expect(closesBefore(space({ openingHours: null }), WINDOW)).toBe("unknown");
        expect(closesBefore(space({ openingHours: "by appointment" }), WINDOW)).toBe("unknown");
    });

    it("never reports a problem for a 24/7 space", () => {
        expect(closesBefore(space({ openingHours: "24/7" }), WINDOW)).toBe("no");
    });
});

describe("explainOption", () => {
    it("produces one explanation row per scoring term", () => {
        const option = { id: "o1", space: space(), window: WINDOW, travel: { a: { minutes: 12 } } };
        const explanation = explainOption(option, { participants: PARTICIPANTS, availability: ALL_FREE });
        expect(explanation.components.map(function keyACB(c) { return c.key; })).toEqual([
            "meanTravel", "maxTravel", "availability", "accessibility", "openingHours", "weather",
        ]);
    });

    it("costs equal the sum of the displayed penalties, so the shown reasons are the real ones", () => {
        const option = {
            id: "o1", space: space(), window: WINDOW,
            travel: { a: { minutes: 12 }, b: { minutes: 20 }, c: { minutes: 30 } },
        };
        const explanation = explainOption(option, { participants: PARTICIPANTS, availability: ALL_FREE });
        const summed = explanation.components.reduce(function addACB(total, c) {
            return total + c.penalty;
        }, 0);
        expect(explanation.cost).toBeCloseTo(summed, 10);
    });

    it("punishes an unfair option more than a uniformly slower one", () => {
        const fair = {
            id: "fair", space: space(), window: WINDOW,
            travel: { a: { minutes: 22 }, b: { minutes: 22 }, c: { minutes: 22 } },
        };
        const unfair = {
            id: "unfair", space: space(), window: WINDOW,
            travel: { a: { minutes: 5 }, b: { minutes: 5 }, c: { minutes: 56 } },
        };
        const context = { participants: PARTICIPANTS, availability: ALL_FREE };
        // Same mean of 22, but the worst journey differs sharply.
        expect(travelStats(fair.travel).mean).toBe(travelStats(unfair.travel).mean);
        expect(explainOption(unfair, context).cost)
            .toBeGreaterThan(explainOption(fair, context).cost);
    });

    it("marks the comparison as incomplete when data is missing", () => {
        const option = { id: "o1", space: space(), window: WINDOW, travel: { a: { minutes: 12 } } };
        const explanation = explainOption(option, { participants: PARTICIPANTS, availability: ALL_FREE });
        expect(explanation.missingData).toBe(true);
    });

    it("respects a raised fairness weight", () => {
        const option = {
            id: "o1", space: space(), window: WINDOW,
            travel: { a: { minutes: 5 }, b: { minutes: 5 }, c: { minutes: 50 } },
        };
        const base = { participants: PARTICIPANTS, availability: ALL_FREE };
        const emphasised = { ...base, weights: { ...WEIGHTS, maxTravel: WEIGHTS.maxTravel * 2 } };
        expect(explainOption(option, emphasised).cost)
            .toBeGreaterThan(explainOption(option, base).cost);
    });
});

describe("rankOptions", () => {
    it("orders by cost and gives the best option the top score", () => {
        const options = [
            {
                id: "slow", space: space(), window: WINDOW,
                travel: { a: { minutes: 40 }, b: { minutes: 45 }, c: { minutes: 50 } },
            },
            {
                id: "quick", space: space(), window: WINDOW,
                travel: { a: { minutes: 10 }, b: { minutes: 12 }, c: { minutes: 14 } },
            },
        ];
        const ranked = rankOptions(options, { participants: PARTICIPANTS, availability: ALL_FREE });
        expect(ranked[0].id).toBe("quick");
        expect(ranked[0].suitability).toBe(100);
        expect(ranked[1].suitability).toBeLessThan(ranked[0].suitability);
    });

    it("does not divide by zero when every option costs the same", () => {
        const identical = {
            id: "a", space: space(), window: WINDOW, travel: { a: { minutes: 10 } },
        };
        const ranked = rankOptions([identical, { ...identical, id: "b" }], {
            participants: [PARTICIPANTS[0]], availability: { a: { intervals: [WINDOW] } },
        });
        expect(ranked.every(function fullACB(o) { return o.suitability === 100; })).toBe(true);
    });

    it("returns an empty list for no options", () => {
        expect(rankOptions([], { participants: [], availability: {} })).toEqual([]);
    });
});

describe("decisionReadiness", () => {
    it("is not ready while somebody has not answered", () => {
        const readiness = decisionReadiness({
            participants: PARTICIPANTS,
            availability: { a: { intervals: [WINDOW] } },
            votes: {},
            options: [{ id: "o1" }],
        });
        expect(readiness.ready).toBe(false);
        expect(readiness.checks.find(function respondedACB(c) {
            return c.key === "responded";
        }).ok).toBe(false);
    });

    it("is ready when everybody has answered and voted", () => {
        const readiness = decisionReadiness({
            participants: PARTICIPANTS,
            availability: ALL_FREE,
            votes: { a: { optionIds: ["o1"] }, b: { optionIds: ["o1"] }, c: { optionIds: ["o1"] } },
            options: [{ id: "o1" }],
        });
        expect(readiness.ready).toBe(true);
    });
});
