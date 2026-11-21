export function InviteView(props) {
    function copyACB() {
        props.copyLink(props.link);
    }
    function openVotingACB() {
        props.openVoting();
    }

    return (
        <div>
            <h1>{props.title}</h1>
            <p class="muted">Invite the group, then watch the answers arrive.</p>

            <div class="card">
                <h2>Share this</h2>
                <p><code>{props.link}</code></p>
                <div class="row">
                    <button class="btn btn--ghost" onClick={copyACB}>Copy invite link</button>
                </div>
                <p class="label" style={{ marginTop: "12px" }}>Or read out the code</p>
                <p style={{ fontSize: "22px", fontWeight: 700, letterSpacing: "3px" }}>
                    {props.inviteCode}
                </p>
            </div>

            <div class="card">
                <div class="row row--between">
                    <h2>Who is in</h2>
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
                <p class="faint" style={{ marginTop: "10px" }}>
                    This list updates live. No reload needed.
                </p>
            </div>

            {props.activity.length
                ? (
                    <div class="card">
                        <h2>Activity</h2>
                        {props.activity.map(function eventACB(event) {
                            return (
                                <p class="muted" key={event.id} style={{ margin: "4px 0" }}>
                                    {event.createdAt
                                        ? `${new Date(event.createdAt).toLocaleTimeString("sv-SE", { timeStyle: "short" })} `
                                        : ""}
                                    {event.summary}
                                </p>
                            );
                        })}
                    </div>
                )
                : null}

            {props.isOrganiser
                ? (
                    <div class="card">
                        <h2>Organiser only</h2>
                        <p class="muted">
                            Opening the vote tells everybody the comparison is ready.
                        </p>
                        <button class="btn" onClick={openVotingACB}
                                disabled={props.status.answered === 0}>
                            Open the vote
                        </button>
                        {props.status.answered === 0
                            ? <p class="faint">Wait for at least one answer.</p>
                            : null}
                    </div>
                )
                : null}
        </div>
    );
}
