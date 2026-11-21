// The separation of concerns is the thing this project is graded on, so it is
// asserted rather than hoped for. These tests read the source files and check
// which layers import which.
//
// Allowed dependency direction:
//
//   views       -> other views only
//   presenters  -> views, model (connect, actions, selectors, slices), router
//   model       -> api, persistence, other model
//   persistence -> firebase, config
//   api         -> config
//
import { describe, expect, it } from "vitest";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";

// Vitest runs with the project root as the working directory.
const SRC = resolve(process.cwd(), "src");

function listFiles(directory) {
    const base = join(SRC, directory);
    const found = [];
    function walkACB(current) {
        readdirSync(current).forEach(function eachACB(entry) {
            const full = join(current, entry);
            if (statSync(full).isDirectory()) {
                if (entry !== "__tests__") {
                    walkACB(full);
                }
            } else if (/\.jsx?$/.test(entry)) {
                found.push(full);
            }
        });
    }
    walkACB(base);
    return found;
}

function importsOf(file) {
    const source = readFileSync(file, "utf8");
    return [...source.matchAll(/(?:^|\n)\s*import\s[^;]*?from\s+["']([^"']+)["']/g)]
        .map(function pathACB(match) { return match[1]; });
}

function offendersIn(directory, isForbidden) {
    const problems = [];
    listFiles(directory).forEach(function eachFileACB(file) {
        importsOf(file).forEach(function eachImportACB(specifier) {
            if (isForbidden(specifier)) {
                problems.push(`${file.replace(SRC, "src")} imports ${specifier}`);
            }
        });
    });
    return problems;
}

describe("views are the View concern only", () => {
    it("never import the store, the model, Firebase or an API source", () => {
        expect(offendersIn("views", function forbiddenACB(specifier) {
            return /model\/|\/store|firebase|persistence\/|api\/|vueRedux/.test(specifier);
        })).toEqual([]);
    });

    it("never import a presenter", () => {
        expect(offendersIn("views", function forbiddenACB(specifier) {
            return /presenter/i.test(specifier);
        })).toEqual([]);
    });

    it("never import the router, so navigation stays a presenter decision", () => {
        expect(offendersIn("views", function forbiddenACB(specifier) {
            // vue-router's RouterView is the one exception: the shell has to
            // mount whatever the router resolved.
            return specifier === "/src/router.js";
        })).toEqual([]);
    });
});

describe("presenters are the Presenter concern only", () => {
    it("never fetch or touch persistence directly", () => {
        expect(offendersIn("presenters", function forbiddenACB(specifier) {
            return /\/api\/|persistence\/|firebase/.test(specifier);
        })).toEqual([]);
    });
});

describe("the model is the Application State concern only", () => {
    it("never imports a view or a presenter", () => {
        expect(offendersIn("model", function forbiddenACB(specifier) {
            return /views\/|presenters\//.test(specifier);
        })).toEqual([]);
    });

    it("keeps Firebase and fetch behind api/ and persistence/", () => {
        const direct = listFiles("model").filter(function usesFirebaseACB(file) {
            if (file.includes("sideEffects")) {
                return false;   // sideEffects is the one wiring point, by design
            }
            return importsOf(file).some(function fbACB(specifier) {
                return /firebase|\/api\/|persistence\//.test(specifier);
            });
        });
        expect(direct).toEqual([]);
    });
});

describe("api sources are the remote-data concern only", () => {
    it("never import the store, persistence or a view", () => {
        expect(offendersIn("api", function forbiddenACB(specifier) {
            return /model\/|persistence\/|views\/|firebase/.test(specifier);
        })).toEqual([]);
    });
});

describe("persistence is the Persistence concern only", () => {
    it("never imports the store, a view or an api source", () => {
        expect(offendersIn("persistence", function forbiddenACB(specifier) {
            return /model\/|views\/|\/api\/|presenters\//.test(specifier);
        })).toEqual([]);
    });
});

describe("one module per view", () => {
    it("exports exactly one view component per view file", () => {
        const manyExports = listFiles("views").filter(function multiACB(file) {
            const source = readFileSync(file, "utf8");
            const exported = [
                ...source.matchAll(/export\s+(?:function|const)\s+([A-Z]\w+)/g),
            ].map(function nameACB(match) { return match[1]; });
            return exported.length > 1;
        });
        expect(manyExports).toEqual([]);
    });
});
