// Firestore hands back Timestamp instances, which are class objects. Keeping
// them out of the store means the application state stays plain, serialisable
// data, so Redux's own checks stay switched on and time is just a number
// everywhere above this layer.
export function plainify(value) {
    if (value === null || typeof value !== "object") {
        return value;
    }
    if (typeof value.toMillis === "function") {
        return value.toMillis();
    }
    if (Array.isArray(value)) {
        return value.map(plainify);
    }
    const result = {};
    Object.keys(value).forEach(function eachKeyACB(key) {
        result[key] = plainify(value[key]);
    });
    return result;
}
