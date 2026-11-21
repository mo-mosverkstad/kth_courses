const PURPOSES = [
    { value: "meeting", label: "Meeting" },
    { value: "study", label: "Study session" },
    { value: "social", label: "Social" },
];

export function CreateView(props) {
    const draft = props.draft;

    function titleACB(event) { props.change({ title: event.target.value }); }
    function durationACB(event) { props.change({ durationMinutes: Number(event.target.value) }); }
    function deadlineACB(event) { props.change({ decisionDeadline: event.target.value }); }
    function dayStartACB(event) { props.change({ newWindowStart: event.target.value }); }
    function dayEndACB(event) { props.change({ newWindowEnd: event.target.value }); }

    function purposeACB(event) { props.change({ purpose: event.target.value }); }

    function addWindowACB() {
        props.addWindow({ start: draft.newWindowStart, end: draft.newWindowEnd });
    }
    function submitACB(event) {
        event.preventDefault();
        props.create();
    }

    const canAdd = Boolean(draft.newWindowStart && draft.newWindowEnd &&
                           draft.newWindowStart < draft.newWindowEnd);
    const canCreate = Boolean(draft.title.trim()) && draft.windows.length > 0;

    return (
        <form onSubmit={submitACB}>
            <h1>New Catch Up</h1>
            <p class="muted">
                Nothing is shared with anybody until you create it.
            </p>

            <div class="card">
                <label class="label" for="title">What is it?</label>
                <input id="title" value={draft.title} onInput={titleACB}
                       placeholder="Project kickoff" required />

                <fieldset style={{ marginTop: "12px" }}>
                    <legend>Purpose &mdash; this only tunes which spaces we suggest</legend>
                    <div class="row">
                        {PURPOSES.map(function purposeOptionACB(purpose) {
                            return (
                                <label class="row" key={purpose.value} style={{ gap: "6px" }}>
                                    <input type="radio" name="purpose" value={purpose.value}
                                           style={{ width: "auto", minHeight: "auto" }}
                                           checked={draft.purpose === purpose.value}
                                           onChange={purposeACB} />
                                    <span>{purpose.label}</span>
                                </label>
                            );
                        })}
                    </div>
                </fieldset>

                <label class="label" for="duration">How long? (minutes)</label>
                <input id="duration" type="number" min="30" max="480" step="30"
                       value={draft.durationMinutes} onInput={durationACB} />

                <label class="label" for="deadline">Decide by</label>
                <input id="deadline" type="datetime-local"
                       value={draft.decisionDeadline} onInput={deadlineACB} />
            </div>

            <div class="card">
                <h2>Possible windows</h2>
                <p class="muted">
                    Add the slots the group could meet in. Members then mark which of them
                    they are free for.
                </p>

                {draft.windows.length
                    ? draft.windows.map(function windowACB(window, index) {
                        function removeACB() { props.removeWindow(index); }
                        return (
                            <div class="row row--between" key={window.start}>
                                <span>
                                    {new Date(window.start).toLocaleString("sv-SE", { dateStyle: "medium", timeStyle: "short" })}
                                    {" to "}
                                    {new Date(window.end).toLocaleTimeString("sv-SE", { timeStyle: "short" })}
                                </span>
                                <button class="btn btn--small btn--ghost" type="button" onClick={removeACB}>
                                    Remove
                                </button>
                            </div>
                        );
                    })
                    : <p class="warn">Add at least one window before creating.</p>}

                <div class="row" style={{ marginTop: "10px", alignItems: "flex-end" }}>
                    <div class="grow">
                        <label class="label" for="winStart">From</label>
                        <input id="winStart" type="datetime-local"
                               value={draft.newWindowStart || ""} onInput={dayStartACB} />
                    </div>
                    <div class="grow">
                        <label class="label" for="winEnd">To</label>
                        <input id="winEnd" type="datetime-local"
                               value={draft.newWindowEnd || ""} onInput={dayEndACB} />
                    </div>
                    <button class="btn btn--ghost" type="button"
                            onClick={addWindowACB} disabled={!canAdd}>
                        Add window
                    </button>
                </div>
            </div>

            <div class="card">
                <h2>What happens next</h2>
                <ol class="muted">
                    <li>You share a link or a code. Members add their own availability and travel limit.</li>
                    <li>We fetch spaces, travel times and weather, then score the options.</li>
                    <li>The group votes, you confirm, and every device updates live.</li>
                </ol>
            </div>

            <button class="btn btn--block" type="submit" disabled={!canCreate || props.busy}>
                {props.busy ? "Creating..." : "Create and invite"}
            </button>
            {!canCreate
                ? <p class="faint">A title and at least one window are needed.</p>
                : null}
        </form>
    );
}
