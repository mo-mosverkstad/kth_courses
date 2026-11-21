// Visibility of system status: what the app is doing right now, and when the
// data on screen was last refreshed. Deliberately non-blocking - it reports,
// it never covers the interface.
export function StatusBarView(props) {
    const checkingSession = props.authStatus === "unknown";
    if (!props.pendingLabels.length && !props.progress && !props.offline && !checkingSession) {
        return null;
    }
    return (
        <div class="statusbar" role="status" aria-live="polite">
            {props.offline
                ? <span class="warn">Offline. Showing the last data received.</span>
                : null}
            {checkingSession
                ? <span class="grow">Checking your session...</span>
                : null}
            {props.progress
                ? (
                    <span class="grow">
                        {props.progress.label}: {props.progress.done} of {props.progress.total}
                        <span class="bar" style={{ display: "block", marginTop: "4px" }}>
                            <span
                                class="bar__fill"
                                style={{ width: `${Math.round((props.progress.done / Math.max(1, props.progress.total)) * 100)}%` }}
                            />
                        </span>
                    </span>
                )
                : null}
            {!props.progress && props.pendingLabels.length
                ? <span class="grow">{props.pendingLabels.join(", ")}...</span>
                : null}
            <span class="faint">You can keep using the app while this finishes.</span>
        </div>
    );
}
