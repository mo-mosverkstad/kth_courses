import { TravelBarsView } from "./travelBarsView.jsx";

// Live voting. Votes arrive from other members through the Firestore listener,
// so this view only ever renders what is already in the application state.
export function VoteView(props) {
    function confirmACB(optionId) {
        return function confirmClickedACB() {
            props.requestConfirm(optionId);
        };
    }

    return (
        <div>
            <div class="row row--between">
                <h1>Vote</h1>
                <span class="muted">{props.tally.voted} of {props.tally.total} voted</span>
            </div>
            <span class="bar" style={{ display: "block", margin: "8px 0 16px" }}>
                <span class="bar__fill" style={{
                    width: `${props.tally.total ? Math.round((props.tally.voted / props.tally.total) * 100) : 0}%`,
                }} />
            </span>

            {props.options.length === 0
                ? <div class="card card--empty">No options to vote on yet.</div>
                : props.options.map(function optionACB(option, index) {
                    function voteACB() { props.vote(option.id); }
                    const voters = props.tally.byOption[option.id] || [];
                    const mine = props.tally.myVotes.includes(option.id);
                    return (
                        <div class={mine ? "card card--selected" : "card"} key={option.id}>
                            <div class="row row--between">
                                <h3>
                                    <span class="pin" style={{ display: "inline-flex", marginRight: "8px" }}>
                                        {index + 1}
                                    </span>
                                    {option.space.name}
                                </h3>
                                <span class="score">{option.suitability}/100</span>
                            </div>
                            <p class="muted">
                                {new Date(option.window.start).toLocaleString("sv-SE", { dateStyle: "medium", timeStyle: "short" })}
                            </p>

                            <TravelBarsView rows={props.travelRowsFor(option)}
                                            stats={option.explanation.stats} />

                            <p class="muted">
                                {voters.length
                                    ? `Voted: ${voters.map(function nameACB(v) { return v.displayName; }).join(", ")}`
                                    : "No votes yet"}
                            </p>

                            <div class="row">
                                <button class={mine ? "btn btn--small" : "btn btn--small btn--ghost"}
                                        onClick={voteACB}>
                                    {mine ? "Your vote (tap to withdraw)" : "Vote"}
                                </button>
                                {props.isOrganiser
                                    ? (
                                        <button class="btn btn--small btn--danger"
                                                onClick={confirmACB(option.id)}>
                                            Confirm this one
                                        </button>
                                    )
                                    : null}
                            </div>
                        </div>
                    );
                })}

            <p class="faint">
                You can change your vote until the organiser confirms. Each vote is stored
                under your own user id, so two people voting at the same moment cannot
                overwrite each other.
            </p>

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
                        <p class="faint">Updates live, no reload.</p>
                    </div>
                )
                : null}

            {props.isOrganiser
                ? (
                    <div class="card card--good">
                        <h2>Decision readiness</h2>
                        {props.readiness.checks.map(function checkACB(check) {
                            return (
                                <p class={check.ok ? "ok" : "warn"} key={check.key}>
                                    {check.ok ? "OK" : "Waiting"}: {check.label}
                                </p>
                            );
                        })}
                        <p class="faint">
                            {props.readiness.ready
                                ? "Everything is in. Confirming now decides for the group."
                                : "You can still confirm, but not everybody has answered."}
                        </p>
                    </div>
                )
                : null}
        </div>
    );
}
