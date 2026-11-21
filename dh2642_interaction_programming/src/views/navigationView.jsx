// One navigation module for all three breakpoints. The CSS decides whether
// this renders as a bottom tab bar, a left icon rail or a labelled sidebar;
// the markup and the labels are identical, so the icons are never unlabelled.
export function NavigationView(props) {
    function itemACB(item) {
        function goACB() {
            props.navigate(item.path);
        }
        return (
            <button
                key={item.path}
                class="nav__item"
                onClick={goACB}
                aria-current={props.activePath.startsWith(item.path) ? "page" : undefined}
            >
                {item.label}
                {item.badge ? <span class="nav__badge">{item.badge}</span> : null}
            </button>
        );
    }

    return (
        <nav class="nav" aria-label="Main">
            {props.items.map(itemACB)}
        </nav>
    );
}
