// A failed request, with a way out. Never a dead end: there is always either
// a retry or an explanation of what to do instead.
export function ErrorPanelView(props) {
    function retryACB() {
        props.retry();
    }
    return (
        <div class="card card--accent" role="alert">
            <h3>{props.title || "That did not work"}</h3>
            <p class="warn">{props.message}</p>
            {props.hint ? <p class="muted">{props.hint}</p> : null}
            {props.retry
                ? <button class="btn btn--ghost" onClick={retryACB}>Try again</button>
                : null}
        </div>
    );
}
