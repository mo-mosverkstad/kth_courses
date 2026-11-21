// Confirmation that an action actually happened. Every write in the app
// produces one of these, so the user is never left guessing.
export function ToastView(props) {
    if (!props.toasts.length) {
        return null;
    }
    return (
        <div class="toasts">
            {props.toasts.map(function toastACB(toast) {
                function dismissACB() {
                    props.dismiss(toast.id);
                }
                return (
                    <div
                        key={toast.id}
                        class={toast.tone === "warn" ? "toast toast--warn" : "toast"}
                        role="status"
                        aria-live="polite"
                    >
                        <span class="grow">{toast.text}</span>
                        <button
                            class="btn btn--small btn--ghost"
                            onClick={dismissACB}
                            aria-label={`Dismiss: ${toast.text}`}
                        >
                            Dismiss
                        </button>
                    </div>
                );
            })}
        </div>
    );
}
