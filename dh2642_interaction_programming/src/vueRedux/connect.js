// A framework-independent Redux binding for Vue.
//
// Why this exists instead of a composable:
//
// A custom hook or composable couples the presenter to the view framework -
// the mapping can only run inside a Vue setup(). Here the mapping functions
// are plain functions of (state) and (dispatch): they contain no Vue API at
// all, can be unit-tested without mounting anything, and would work unchanged
// against a React renderer. Only this one file knows about Vue.
//
// The shape is deliberately the same as react-redux's connect(), so a
// presenter reads as two pure mappings and nothing else.
import { defineComponent, h, onUnmounted, shallowRef } from "vue";
import { store } from "/src/model/store.js";

function shallowEqual(a, b) {
    if (a === b) {
        return true;
    }
    if (!a || !b) {
        return false;
    }
    const keysA = Object.keys(a);
    const keysB = Object.keys(b);
    if (keysA.length !== keysB.length) {
        return false;
    }
    return keysA.every(function sameACB(key) {
        return a[key] === b[key];
    });
}

export function connect(mapStateToProps, mapDispatchToProps) {
    return function connectViewACB(View) {
        return defineComponent({
            name: `Connected${View.name || "View"}`,
            inheritAttrs: false,

            setup(_props, context) {
                // Dispatch props are built once: they are stable callbacks.
                const dispatchProps = typeof mapDispatchToProps === "function"
                    ? mapDispatchToProps(store.dispatch)
                    : {};

                function currentStatePropsACB() {
                    return typeof mapStateToProps === "function"
                        ? mapStateToProps(store.getState(), context.attrs)
                        : {};
                }

                const stateProps = shallowRef(currentStatePropsACB());

                // Re-map on every store change, but only trigger a re-render
                // when the mapped result actually differs. Without this, every
                // dispatch would re-render every connected view.
                function storeChangedACB() {
                    const next = currentStatePropsACB();
                    if (!shallowEqual(next, stateProps.value)) {
                        stateProps.value = next;
                    }
                }

                const unsubscribe = store.subscribe(storeChangedACB);
                onUnmounted(unsubscribe);

                return function renderConnectedACB() {
                    return h(
                        View,
                        { ...stateProps.value, ...dispatchProps, ...context.attrs },
                        context.slots,
                    );
                };
            },
        });
    };
}
