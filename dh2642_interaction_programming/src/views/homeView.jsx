function statusLabel(meetup) {
    if (meetup.status === "confirmed") { return "Confirmed"; }
    if (meetup.status === "voting") { return "Voting open"; }
    return "Collecting availability";
}

export function HomeView(props) {
    function newACB() { props.createNew(); }

    function cardACB(meetup) {
        function openACB() { props.open(meetup.id); }
        const responded = (meetup.respondedIds || []).length;
        const total = (meetup.memberIds || []).length;
        return (
            <div class="card" key={meetup.id}>
                <h3>{meetup.title}</h3>
                <p class="muted">
                    {statusLabel(meetup)} &middot; {responded} of {total} added availability
                </p>
                <span class="bar" style={{ display: "block", margin: "6px 0" }}>
                    <span class="bar__fill"
                          style={{ width: `${total ? Math.round((responded / total) * 100) : 0}%` }} />
                </span>
                <div class="row">
                    <button class="btn btn--small" onClick={openACB}>Open</button>
                    {meetup.inviteCode
                        ? <span class="faint">code {meetup.inviteCode}</span>
                        : null}
                </div>
            </div>
        );
    }

    const summaries = props.summaries;

    return (
        <div>
            <div class="row row--between">
                <h1>My Catch Ups</h1>
                <button class="btn" onClick={newACB}>+ New Catch Up</button>
            </div>

            {props.defaults.startingArea
                ? (
                    <div class="card card--good">
                        <h3>Your saved defaults</h3>
                        <p class="muted">
                            {props.defaults.startingArea} &middot; max {props.defaults.maxTravelMinutes} min
                            {props.defaults.needs.length ? ` · ${props.defaults.needs.join(", ")}` : ""}
                        </p>
                        <p class="ok">
                            Applied automatically to every new Catch Up, so you never retype them.
                        </p>
                    </div>
                )
                : null}

            {summaries.needsMe.length
                ? (
                    <div>
                        <h2 class="sectionTitle">Needs you ({summaries.needsMe.length})</h2>
                        {summaries.needsMe.map(cardACB)}
                    </div>
                )
                : null}

            <h2 class="sectionTitle">Voting now</h2>
            {summaries.voting.length
                ? <div class="grid">{summaries.voting.map(cardACB)}</div>
                : <div class="card card--empty">Nothing open for voting right now.</div>}

            <h2 class="sectionTitle">Confirmed</h2>
            {summaries.upcoming.length
                ? <div class="grid">{summaries.upcoming.map(cardACB)}</div>
                : <div class="card card--empty">No confirmed meetings yet.</div>}

            <h2 class="sectionTitle">Collecting availability</h2>
            {summaries.collecting.length
                ? <div class="grid">{summaries.collecting.map(cardACB)}</div>
                : (
                    <div class="card card--empty">
                        <p>Nothing in progress.</p>
                        <button class="btn btn--ghost" onClick={newACB}>Start a Catch Up</button>
                    </div>
                )}
        </div>
    );
}
