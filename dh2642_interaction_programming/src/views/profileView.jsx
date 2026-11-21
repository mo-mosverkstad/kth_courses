const NEEDS = [
    { value: "stepFree", label: "Step-free entrance" },
    { value: "wifi", label: "Wi-Fi" },
    { value: "power", label: "Power outlets" },
    { value: "food", label: "Food nearby" },
];

export function ProfileView(props) {
    function areaACB(event) { props.change({ startingArea: event.target.value }); }
    function limitACB(event) { props.change({ maxTravelMinutes: Number(event.target.value) }); }

    function saveACB(event) {
        event.preventDefault();
        props.save(props.form);
    }
    function toggleNeedACB(value) {
        return function toggledACB() {
            const needs = props.form.needs.includes(value)
                ? props.form.needs.filter(function dropACB(need) { return need !== value; })
                : [...props.form.needs, value];
            props.change({ needs });
        };
    }
    function toggleShareACB() {
        props.change({ shareStartingArea: !props.form.shareStartingArea });
    }
    function signOutACB() {
        props.signOut();
    }

    return (
        <form onSubmit={saveACB}>
            <h1>Profile</h1>
            <p class="muted">{props.displayName} &middot; {props.email}</p>

            <div class="card">
                <h2>My usual answers</h2>
                <p class="muted">
                    These are filled in automatically for every new Catch Up, so you do
                    not retype them. You can still change them per meeting.
                </p>

                <label class="label" for="defaultArea">Usual starting area</label>
                <input id="defaultArea" value={props.form.startingArea} onInput={areaACB}
                       placeholder="Odenplan" />

                <label class="label" for="defaultLimit" style={{ marginTop: "12px" }}>
                    Usual maximum travel time: {props.form.maxTravelMinutes} minutes
                </label>
                <input id="defaultLimit" type="range" min="10" max="90" step="5"
                       value={props.form.maxTravelMinutes} onInput={limitACB} />

                <fieldset style={{ marginTop: "12px" }}>
                    <legend>What I usually need</legend>
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
            </div>

            <div class="card">
                <h2>Privacy</h2>
                <button type="button" class="chip"
                        aria-pressed={props.form.shareStartingArea ? "true" : "false"}
                        onClick={toggleShareACB}>
                    {props.form.shareStartingArea
                        ? "Sharing my starting area with members"
                        : "Not sharing my starting area"}
                </button>
                <p class="faint" style={{ marginTop: "8px" }}>
                    Your travel time is always shown to the group, because that is what the
                    comparison is about. The area it starts from is only shown if you turn
                    this on.
                </p>
            </div>

            <button class="btn btn--block" type="submit">Save defaults</button>
            {props.savedRecently ? <p class="ok">Saved.</p> : null}

            <button class="btn btn--ghost btn--block" type="button"
                    style={{ marginTop: "16px" }} onClick={signOutACB}>
                Sign out
            </button>
        </form>
    );
}
