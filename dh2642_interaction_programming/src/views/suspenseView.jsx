// Loading placeholder. Shaped like the content it replaces, so the layout
// does not jump when the data arrives.
export function SuspenseView(props) {
    const rows = props.rows || 3;
    const lines = [];
    for (let i = 0; i < rows; i += 1) {
        lines.push(<div class="skeleton" style={{ width: `${90 - i * 12}%` }} />);
    }
    return (
        <div class="card" aria-busy="true">
            <p class="muted">{props.label || "Loading..."}</p>
            {lines}
            <span class="visuallyHidden" role="status">{props.label || "Loading"}</span>
        </div>
    );
}
