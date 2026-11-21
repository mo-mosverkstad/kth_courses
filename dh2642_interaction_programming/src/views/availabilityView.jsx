const NEEDS = [
    { value: "stepFree", label: "Step-free entrance" },
    { value: "wifi", label: "Wi-Fi" },
    { value: "power", label: "Power outlets" },
    { value: "food", label: "Food nearby" },
];

export function AvailabilityView(props) {
    function areaACB(event) { props.change({ startingAreaDraft: event.target.value }); }
    function limitACB(event) { props.change({ maxTravelMinutes: Number(event.target.value) }); }

    function lookUpACB(event) {
        event.preventDefault();
        props.resolveArea(props.form.startingAreaDraft);
    }

    function toggleNeedACB(value) {
        return function needToggledACB() {
            const needs = props.form.needs.includes(value)
                ? props.form.needs.filter(function dropACB(need) { return need !== value; })
                : [...props.form.needs, value];
            props.savePreferences({ needs });
        };
    }

    function toggleWindowACB(window) {
        return function windowToggledACB() {
            props.toggleWindow(window);
        };
    }

    function saveLimitACB() {
        props.savePreferences({ maxTravelMinutes: props.form.maxTravelMinutes });
    }

    return (
        <div>
            <h1>My availability</h1>
            <p class="muted">
                Only you can change this. Everybody else edits their own entry, so nothing
                you enter can be overwritten by another member.
            </p>

            <div class="card">
                <h2>Which windows work for you?</h2>
                {props.windows.length
                    ? props.windows.map(function windowACB(window) {
                        const chosen = props.myIntervals.some(function matchACB(interval) {
                            return interval.start === window.start;
                        });
                        return (
                            <button
                                key={window.start}
                                type="button"
                                class="chip"
                                style={{ display: "block", width: "100%", textAlign: "left", marginBottom: "8px" }}
                                aria-pressed={chosen ? "true" : "false"}
                                onClick={toggleWindowACB(window)}
                            >
                                {chosen ? "Free: " : "Not free: "}
                                {new Date(window.start).toLocaleString("sv-SE", { dateStyle: "medium", timeStyle: "short" })}
                                {" to "}
                                {new Date(window.end).toLocaleTimeString("sv-SE", { timeStyle: "short" })}
                            </button>
                        );
                    })
                    : <p class="warn">The organiser has not added any windows yet.</p>}
                {props.savedAt
                    ? <p class="ok">Saved {new Date(props.savedAt).toLocaleTimeString("sv-SE", { timeStyle: "short" })}</p>
                    : null}
            </div>

            <form class="card" onSubmit={lookUpACB}>
                <h2>Where do you travel from?</h2>
                <label class="label" for="area">Starting area</label>
                <input id="area" value={props.form.startingAreaDraft} onInput={areaACB}
                       placeholder="Odenplan" />
                <p class="faint">
                    Area level only, such as a stop or a neighbourhood. Never your exact
                    address. Shared with the group only if you turn that on in your profile.
                </p>
                <button class="btn btn--ghost" type="submit" disabled={props.resolving}>
                    {props.resolving ? "Looking up..." : "Look up this area"}
                </button>
                {props.resolveError
                    ? <p class="warn" role="alert">{props.resolveError}</p>
                    : null}
                {props.resolvedArea
                    ? <p class="ok">Using {props.resolvedArea}</p>
                    : null}
            </form>

            <div class="card">
                <h2>My limits</h2>
                <label class="label" for="limit">
                    Maximum travel time: {props.form.maxTravelMinutes} minutes
                </label>
                <input id="limit" type="range" min="10" max="90" step="5"
                       value={props.form.maxTravelMinutes}
                       onInput={limitACB} onChange={saveLimitACB} />

                <fieldset style={{ marginTop: "12px" }}>
                    <legend>What I need from the space</legend>
                    <div class="row">
                        {NEEDS.map(function needACB(need) {
                            return (
                                <button key={need.value} type="button" class="chip"
                                        aria-pressed={props.form.needs.includes(need.value) ? "true" : "false"}
                                        onClick={toggleNeedACB(need.value)}>
                                    {need.label}
                                </button>
                            );
                        })}
                    </div>
                </fieldset>
                <p class="faint">
                    Step-free is treated as a hard requirement: a space is only counted as
                    accessible if OpenStreetMap actually says so.
                </p>
            </div>

            <button class="btn btn--block" onClick={props.done}>See the options</button>
        </div>
    );
}
