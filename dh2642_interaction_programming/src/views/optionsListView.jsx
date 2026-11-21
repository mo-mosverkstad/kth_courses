import { TravelBarsView } from "./travelBarsView.jsx";

// The candidate list. One card per option, each carrying every member's
// journey rather than a single average, and each able to fail on its own.
export function OptionsListView(props) {
    function sortACB(event) { props.changeSort(event.target.value); }

    function cardACB(option, index) {
        function selectACB() { props.select(option.id); }
        function retryACB() { props.retry(option.id); }
        function voteACB() { props.vote(option.id); }

        const explanation = option.explanation;
        const request = props.requestFor(option.id);
        const incomplete = explanation.missingData;

        return (
            <div
                class={option.id === props.selectedId ? "card card--selected" : "card"}
                key={option.id}
            >
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
                    {" to "}
                    {new Date(option.window.end).toLocaleTimeString("sv-SE", { timeStyle: "short" })}
                </p>

                <TravelBarsView rows={props.travelRowsFor(option)} stats={explanation.stats} />

                <p class={explanation.unmet.length ? "warn" : "ok"}>
                    {explanation.free} of {props.participantCount} free
                    {explanation.unmet.length
                        ? ` · ${explanation.unmet.length} accessibility requirement(s) unmet`
                        : " · accessibility requirements satisfied"}
                </p>

                {incomplete
                    ? (
                        <p class="warn">
                            Comparison is partial: some data could not be fetched.
                        </p>
                    )
                    : null}

                {request.status === "pending"
                    ? <p class="muted">Refreshing this space...</p>
                    : null}
                {request.status === "rejected"
                    ? <p class="warn" role="alert">{request.error}</p>
                    : null}

                <div class="row">
                    <button class="btn btn--small" onClick={selectACB}>Why this one?</button>
                    {props.canVote
                        ? (
                            <button
                                class={props.myVotes.includes(option.id) ? "btn btn--small" : "btn btn--small btn--ghost"}
                                onClick={voteACB}
                            >
                                {props.myVotes.includes(option.id) ? "Your vote" : "Vote"}
                            </button>
                        )
                        : null}
                    {incomplete || request.status === "rejected"
                        ? (
                            <button class="btn btn--small btn--ghost" onClick={retryACB}>
                                Retry this space
                            </button>
                        )
                        : null}
                </div>
            </div>
        );
    }

    if (props.options.length === 0) {
        return (
            <div class="card card--empty">
                <p>No options yet.</p>
                <p class="faint">
                    Make sure the organiser added windows, that members entered a starting
                    area, then search for spaces.
                </p>
                <button class="btn" onClick={props.refresh}>Search for spaces</button>
            </div>
        );
    }

    return (
        <div>
            <div class="row row--between">
                <strong>{props.options.length} options</strong>
                <span>
                    <label class="visuallyHidden" for="sort">Sort options by</label>
                    <select id="sort" value={props.sortBy} onChange={sortACB}
                            style={{ width: "auto", minHeight: "36px" }}>
                        <option value="best">Best overall</option>
                        <option value="meanTravel">Shortest average travel</option>
                        <option value="maxTravel">Fairest worst journey</option>
                    </select>
                </span>
            </div>

            {props.searchArea
                ? (
                    <p class="faint">
                        Searched {props.searchArea.label.toLowerCase()}, within
                        {" "}{Math.round(props.searchArea.radiusMetres / 1000)} km.
                        {props.searchArea.memberCount === 1
                            ? " Add more starting areas and the search moves with the group."
                            : ""}
                    </p>
                )
                : null}

            <p class="faint">
                Selecting a card highlights it on the map and updates the explanation.
            </p>

            {props.options.map(cardACB)}

            <button class="btn btn--ghost btn--block" onClick={props.refresh}>
                Search for spaces again
            </button>
        </div>
    );
}
