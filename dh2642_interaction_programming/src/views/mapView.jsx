// The user-visible third-party component: MapLibre GL JS.
//
// This is the one view that owns an imperative library, so it is also the one
// view allowed a lifecycle: the map instance and its markers are not
// application state, they are a rendering detail of this module. Everything
// the map shows arrives through props, and every click leaves through a
// callback prop.
import { defineComponent, h, onMounted, onUnmounted, ref, watch } from "vue";
import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
import { MAP_TILE_ATTRIBUTION, MAP_TILE_URL } from "/src/apiConfig.js";

function rasterStyle() {
    return {
        version: 8,
        sources: {
            osm: {
                type: "raster",
                tiles: [MAP_TILE_URL],
                tileSize: 256,
                attribution: MAP_TILE_ATTRIBUTION,
            },
        },
        layers: [{ id: "osm", type: "raster", source: "osm" }],
    };
}

export const MapView = defineComponent({
    name: "MapView",
    props: {
        spaces: { type: Array, default: function spacesACB() { return []; } },
        starts: { type: Array, default: function startsACB() { return []; } },
        selectedId: { type: String, default: null },
        tall: { type: Boolean, default: false },
        onSelect: { type: Function, default: null },
    },

    setup(props) {
        const container = ref(null);
        let map = null;
        let markers = [];

        function clearMarkersACB() {
            markers.forEach(function removeACB(marker) { marker.remove(); });
            markers = [];
        }

        function drawMarkersACB() {
            if (!map) {
                return;
            }
            clearMarkersACB();

            props.starts.forEach(function startACB(start) {
                const dot = document.createElement("div");
                dot.style.cssText =
                    "width:12px;height:12px;border-radius:50%;background:#5a6472;border:2px solid #fff";
                dot.title = `${start.name} starts here`;
                markers.push(new maplibregl.Marker({ element: dot })
                    .setLngLat([start.lon, start.lat])
                    .addTo(map));
            });

            props.spaces.forEach(function spaceACB(space, index) {
                const pin = document.createElement("button");
                pin.type = "button";
                pin.className = space.id === props.selectedId ? "pin pin--selected" : "pin";
                pin.textContent = String(index + 1);
                pin.setAttribute("aria-label", `Select ${space.name}`);
                pin.addEventListener("click", function pinClickedACB(event) {
                    event.stopPropagation();
                    if (props.onSelect) {
                        props.onSelect(space.id);
                    }
                });
                markers.push(new maplibregl.Marker({ element: pin })
                    .setLngLat([space.lon, space.lat])
                    .addTo(map));
            });
        }

        function fitACB() {
            const points = [
                ...props.spaces.map(function spaceACB(s) { return [s.lon, s.lat]; }),
                ...props.starts.map(function startACB(s) { return [s.lon, s.lat]; }),
            ];
            if (!map || points.length === 0) {
                return;
            }
            if (points.length === 1) {
                map.jumpTo({ center: points[0], zoom: 13 });
                return;
            }
            const bounds = points.reduce(function extendACB(box, point) {
                return box.extend(point);
            }, new maplibregl.LngLatBounds(points[0], points[0]));
            map.fitBounds(bounds, { padding: 48, maxZoom: 15, animate: false });
        }

        onMounted(function mountMapACB() {
            map = new maplibregl.Map({
                container: container.value,
                style: rasterStyle(),
                center: [18.0527, 59.3426],
                zoom: 11,
                attributionControl: true,
            });
            map.addControl(new maplibregl.NavigationControl({ showCompass: false }), "top-right");
            map.on("load", function loadedACB() {
                drawMarkersACB();
                fitACB();
            });
        });

        onUnmounted(function unmountMapACB() {
            clearMarkersACB();
            if (map) {
                map.remove();
                map = null;
            }
        });

        watch(function spacesWatchACB() {
            return [props.spaces, props.selectedId];
        }, function spacesChangedACB() {
            drawMarkersACB();
        }, { deep: false });

        watch(function countWatchACB() {
            return props.spaces.length;
        }, function countChangedACB() {
            fitACB();
        });

        return function renderMapACB() {
            return h("div", {
                class: props.tall ? "map map--tall" : "map",
                ref: container,
                role: "application",
                "aria-label": "Map of candidate spaces. The same information is in the list below.",
            });
        };
    },
});
