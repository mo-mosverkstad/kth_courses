// Meeting overview: where the group is in the process, and the single most
// useful next action for this particular user.
export function OverviewView(props) {
    function nextACB() { props.goNext(); }
    function inviteACB() { props.goInvite(); }

    return (
        <div>
            <h1>{props.title}</h1>
            <p class="muted">
                {props.purpose} &middot; {props.durationMinutes} minutes
                {props.decisionDeadline
                    ? ` · decide by ${new Date(props.decisionDeadline).toLocaleString("sv-SE", { dateStyle: "medium", timeStyle: "short" })}`
                    : ""}
            </p>

            <div class="card card--accent">
                <h2>{props.nextLabel}</h2>
                <p class="muted">{props.nextHint}</p>
                <button class="btn" onClick={nextACB}>{props.nextAction}</button>
            </div>

            {props.inviteCode
                ? (
                    <div class="card">
                        <div class="row row--between">
                            <h2>Invite code</h2>
                            <button class="btn btn--small btn--ghost" onClick={inviteACB}>
                                Share this Catch Up
                            </button>
                        </div>
                        <p style={{ fontSize: "22px", fontWeight: 700, letterSpacing: "3px" }}>
                            {props.inviteCode}
                        </p>
                        <p class="faint">
                            {props.memberCount === 1
                                ? "You are the only member so far. Anyone with this code can join and add their availability."
                                : `${props.memberCount} members have joined. Anyone with this code can still join.`}
                        </p>
                    </div>
                )
                : null}

            <div class="card">
                <div class="row row--between">
                    <h2>Responses</h2>
                    <strong>{props.status.answered} of {props.status.total}</strong>
                </div>
                <span class="bar" style={{ display: "block", margin: "8px 0" }}>
                    <span class="bar__fill" style={{
                        width: `${props.status.total ? Math.round((props.status.answered / props.status.total) * 100) : 0}%`,
                    }} />
                </span>
                {props.status.rows.map(function rowACB(row) {
                    return (
                        <div class="row row--between" key={row.uid}>
                            <span>{row.displayName}</span>
                            <span class={row.answered ? "ok" : "warn"}>
                                {row.answered ? "answered" : "waiting"}
                            </span>
                        </div>
                    );
                })}
            </div>

            <div class="card">
                <h2>Windows under consideration</h2>
                {props.windows.length
                    ? props.windows.map(function windowACB(window) {
                        return (
                            <p class="muted" key={window.start}>
                                {new Date(window.start).toLocaleString("sv-SE", { dateStyle: "medium", timeStyle: "short" })}
                                {" to "}
                                {new Date(window.end).toLocaleTimeString("sv-SE", { timeStyle: "short" })}
                            </p>
                        );
                    })
                    : <p class="warn">No windows yet.</p>}
            </div>
        </div>
    );
}
