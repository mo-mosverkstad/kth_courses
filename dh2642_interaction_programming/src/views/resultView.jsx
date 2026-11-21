import { TravelBarsView } from "./travelBarsView.jsx";

export function ResultView(props) {
    const option = props.option;

    if (!option) {
        return (
            <div class="card card--empty">
                <p>Nothing confirmed yet.</p>
                <button class="btn btn--ghost" onClick={props.goToVote}>Go to the vote</button>
            </div>
        );
    }

    function reopenACB() { props.requestReopen(); }
    function calendarACB() { props.exportCalendar(option); }

    return (
        <div>
            <div class="card card--good">
                <h1>It is settled</h1>
                <h2>{props.title}</h2>
                <p>
                    <strong>
                        {new Date(option.window.start).toLocaleString("sv-SE", { dateStyle: "full", timeStyle: "short" })}
                        {" to "}
                        {new Date(option.window.end).toLocaleTimeString("sv-SE", { timeStyle: "short" })}
                    </strong>
                </p>
                <p>{option.space.name}{option.space.address ? `, ${option.space.address}` : ""}</p>
                <p class="ok">Everyone sees this plan, on every device.</p>
            </div>

            <div class="card">
                <h3>Journeys</h3>
                <TravelBarsView rows={props.travelRows} stats={option.explanation.stats} />
                {props.myMinutes
                    ? (
                        <p class="muted">
                            Your trip is {props.myMinutes} minutes, so leave by
                            {" "}{props.leaveBy}.
                        </p>
                    )
                    : null}
                {option.weather && option.weather.precipitationPercent !== null
                    ? (
                        <p class="muted">
                            Weather at the start: {option.weather.temperatureC}&deg;C,
                            {" "}{option.weather.precipitationPercent}% chance of rain.
                        </p>
                    )
                    : null}
            </div>

            <button class="btn btn--block" onClick={calendarACB}>
                Add to calendar (.ics)
            </button>

            {props.isOrganiser
                ? (
                    <button class="btn btn--danger btn--block" style={{ marginTop: "16px" }}
                            onClick={reopenACB}>
                        Reopen the decision
                    </button>
                )
                : null}
            {props.isOrganiser
                ? <p class="faint">This asks for confirmation, and everybody is notified.</p>
                : null}
        </div>
    );
}
