// One bar per participant, never a single average.
//
// This is the view that carries the whole fairness argument, so it is a module
// of its own and is reused by the option card, the detail pane and the result
// screen. A journey over that person's own limit is marked, and it does not
// rely on colour alone to say so.
export function TravelBarsView(props) {
    const rows = props.rows || [];
    const scale = Math.max(
        1,
        ...rows.map(function minutesACB(row) { return row.minutes || 0; }),
    );

    return (
        <div>
            {rows.map(function rowACB(row) {
                const over = row.limit && row.minutes && row.minutes > row.limit;
                const width = row.minutes ? Math.round((row.minutes / scale) * 100) : 0;
                return (
                    <div class="travelRow" key={row.uid}>
                        <span class="travelRow__name">{row.name}</span>
                        <span class="travelRow__bar">
                            <span class="bar">
                                <span
                                    class={over ? "bar__fill bar__fill--warn" : "bar__fill"}
                                    style={{ width: `${width}%` }}
                                />
                            </span>
                        </span>
                        <span class="travelRow__value">
                            {row.minutes ? `${row.minutes} min` : "no data"}
                            {over ? " !" : ""}
                        </span>
                    </div>
                );
            })}
            {props.stats && props.stats.mean !== null
                ? (
                    <p class="muted" style={{ marginTop: "6px" }}>
                        average {props.stats.mean} min, longest {props.stats.max} min
                        {props.stats.estimated ? " (estimated from distance)" : ""}
                    </p>
                )
                : null}
            {rows.some(function overACB(row) {
                return row.limit && row.minutes && row.minutes > row.limit;
            })
                ? <p class="warn">! marks a journey longer than that person's own limit.</p>
                : null}
        </div>
    );
}
