import { MapView } from "./mapView.jsx";
import { OptionsListView } from "./optionsListView.jsx";
import { OptionDetailView } from "./optionDetailView.jsx";

// Arranges the three option views for the current breakpoint. This module owns
// the arrangement only: the list, the map and the detail are separate view
// modules with their own responsibilities, and all three receive the same
// props regardless of layout.
//
//   phone           map and list as two tabs, detail reached by selection
//   tabletPortrait  map above the list, both visible
//   wide            three panes, no navigation needed
export function OptionsScreenView(props) {
    function showListACB() { props.choosePane("list"); }
    function showMapACB() { props.choosePane("map"); }

    const map = (
        <MapView
            spaces={props.spaces}
            starts={props.starts}
            selectedId={props.selectedId}
            tall={props.breakpoint === "wide"}
            onSelect={props.select}
        />
    );
    const list = <OptionsListView {...props} />;
    const detail = <OptionDetailView {...props} />;

    if (props.breakpoint === "wide") {
        return (
            <div class="panes">
                <div>{list}</div>
                <div>{map}</div>
                <div>{detail}</div>
            </div>
        );
    }

    if (props.breakpoint === "tabletPortrait") {
        return (
            <div class="panes">
                {map}
                <div class="grid">
                    <div>{list}</div>
                    <div>{detail}</div>
                </div>
            </div>
        );
    }

    return (
        <div>
            <div class="paneTabs" role="tablist" aria-label="Show options as">
                <button class="chip" role="tab" onClick={showListACB}
                        aria-selected={props.pane === "list" ? "true" : "false"}
                        aria-pressed={props.pane === "list" ? "true" : "false"}>
                    List
                </button>
                <button class="chip" role="tab" onClick={showMapACB}
                        aria-selected={props.pane === "map" ? "true" : "false"}
                        aria-pressed={props.pane === "map" ? "true" : "false"}>
                    Map
                </button>
            </div>
            {props.pane === "map" ? map : null}
            {list}
            {props.selectedId ? detail : null}
        </div>
    );
}
