// The stage strip inside one meeting: Overview, Availability, Options, Vote,
// Result. On a phone this is a horizontal scroller; at the wide breakpoint the
// sidebar shows the same stages, driven by the same props.
export function MeetupStagesView(props) {
    function stageACB(stage) {
        function goACB() { props.navigate(stage.path); }
        const active = props.activePath.endsWith(stage.path);
        return (
            <button
                key={stage.path}
                type="button"
                class="chip"
                aria-pressed={active ? "true" : "false"}
                aria-current={active ? "step" : undefined}
                onClick={goACB}
            >
                {stage.label}
            </button>
        );
    }

    return (
        <div>
            <div class="row" style={{ overflowX: "auto", paddingBottom: "4px" }}>
                {props.stages.map(stageACB)}
            </div>
            {props.subtitle ? <p class="faint">{props.subtitle}</p> : null}
        </div>
    );
}
