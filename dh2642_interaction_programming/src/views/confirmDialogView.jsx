// Anything hard to undo goes through here first, with the consequence spelled
// out rather than a generic "are you sure".
export function ConfirmDialogView(props) {
    if (!props.dialog) {
        return null;
    }
    function cancelACB() {
        props.cancel();
    }
    function confirmACB() {
        props.confirm(props.dialog);
    }
    return (
        <div class="backdrop" role="dialog" aria-modal="true" aria-label={props.dialog.title}>
            <div class="dialog">
                <h2>{props.dialog.title}</h2>
                <p>{props.dialog.body}</p>
                {props.dialog.consequence
                    ? <p class="warn">{props.dialog.consequence}</p>
                    : null}
                <div class="row row--between">
                    <button class="btn btn--ghost" onClick={cancelACB}>Cancel</button>
                    <button class="btn" onClick={confirmACB}>{props.dialog.confirmLabel || "Confirm"}</button>
                </div>
            </div>
        </div>
    );
}
