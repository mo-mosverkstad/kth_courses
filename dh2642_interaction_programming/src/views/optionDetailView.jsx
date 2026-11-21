import { TravelBarsView } from "./travelBarsView.jsx";

function facilityLabel(state) {
    if (state === "yes") { return "yes"; }
    if (state === "no") { return "no"; }
    return "not recorded";
}

// "Why this one?" - the whole point of the app. Every term that contributed to
// the score produces a row here, so the ranking is inspectable rather than
// something the user has to trust.
export function OptionDetailView(props) {
    const option = props.option;
    if (!option) {
        return (
            <div class="card card--empty">
                Select an option to see why it is ranked where it is.
            </div>
        );
    }

    function emphasisACB() { props.toggleEmphasis(); }
    function voteACB() { props.vote(option.id); }

    const explanation = option.explanation;

    return (
        <div>
            <div class="card">
                <div class="row row--between">
                    <h2>{option.space.name}</h2>
                    <span class="score">{option.suitability} / 100</span>
                </div>
                <p class="muted">
                    {option.space.address || option.space.category}
                    {" · "}
                    {new Date(option.window.start).toLocaleString("sv-SE", { dateStyle: "medium", timeStyle: "short" })}
                </p>

                <h3 style={{ marginTop: "12px" }}>Travel time per member</h3>
                <TravelBarsView rows={props.travelRows} stats={explanation.stats} />
            </div>

            <div class="card">
                <h3>How we got to {option.suitability}</h3>
                <table class="breakdown">
                    <thead>
                        <tr>
                            <th>Factor</th>
                            <th>Value</th>
                            <th>Cost</th>
                        </tr>
                    </thead>
                    <tbody>
                        {explanation.components.map(function componentACB(component) {
                            return (
                                <tr key={component.key}>
                                    <td>{component.label}</td>
                                    <td class={component.status === "warn" ? "warn" : "muted"}>
                                        {component.value}
                                    </td>
                                    <td>{component.penalty ? `-${Math.round(component.penalty)}` : "0"}</td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
                <p class="faint" style={{ marginTop: "8px" }}>
                    A lower total cost ranks higher. The score is scaled against the best
                    and worst option we actually found, so it compares these alternatives
                    rather than claiming an absolute rating.
                </p>

                <button class="btn btn--ghost btn--block" onClick={emphasisACB}
                        aria-pressed={props.fairnessEmphasis ? "true" : "false"}>
                    {props.fairnessEmphasis
                        ? "Fairness weighted higher (tap to reset)"
                        : "Weigh fairness higher"}
                </button>
                <p class="faint">
                    This doubles the weight of the longest single journey. The weights are
                    design assumptions we intend to test with users, not facts.
                </p>
            </div>

            {explanation.unmet.length
                ? (
                    <div class="card card--accent">
                        <h3>Unmet requirements</h3>
                        {explanation.unmet.map(function unmetACB(entry) {
                            return (
                                <p class="warn" key={`${entry.uid}-${entry.need}`}>
                                    {entry.name} needs {entry.need}, this space records
                                    {" "}{facilityLabel(entry.state)}.
                                </p>
                            );
                        })}
                    </div>
                )
                : null}

            <div class="card">
                <h3>Space, from OpenStreetMap</h3>
                <p class="muted">
                    Step-free: {facilityLabel(option.space.facilities.stepFree)}
                    {" · Wi-Fi: "}{facilityLabel(option.space.facilities.wifi)}
                    {" · Power: "}{facilityLabel(option.space.facilities.power)}
                </p>
                <p class="muted">
                    Opening hours: {option.space.openingHours || "not recorded"}
                </p>
                <p class="warn">
                    OpenStreetMap data may be incomplete. We show what the source says and
                    do not treat a missing tag as a yes.
                </p>
                {option.fetchedAt
                    ? (
                        <p class="faint">
                            Travel and weather fetched
                            {" "}{new Date(option.fetchedAt).toLocaleTimeString("sv-SE", { timeStyle: "short" })}
                        </p>
                    )
                    : null}
            </div>

            {props.canVote
                ? (
                    <button class="btn btn--block" onClick={voteACB}>
                        {props.myVotes.includes(option.id)
                            ? "Remove my vote"
                            : "Vote for this option"}
                    </button>
                )
                : null}
            <p class="faint">
                The app recommends, the group decides. A lower-ranked option is always
                selectable.
            </p>
        </div>
    );
}
