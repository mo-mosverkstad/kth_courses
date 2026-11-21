import { defineConfig } from "vite";
import vueJsxPlugin from "@vitejs/plugin-vue-jsx";

// Keep the dependency-optimizer cache off the Windows filesystem when the dev
// server is started from WSL.
//
// Vite optimizes dependencies by writing node_modules/.vite/deps_temp_xxx and
// then renaming it over node_modules/.vite/deps. On /mnt/c that rename can
// fail with EACCES, because DrvFs does not allow replacing a directory whose
// files are held open - and OneDrive sync holds them open. The failure leaves
// only deps_temp_* behind with no deps directory, after which every optimized
// import returns "504 Outdated Optimize Dep" until the cache is deleted by
// hand. Putting the cache on the Linux filesystem avoids the rename entirely.
const startedFromWslOnWindowsDrive =
    process.platform === "linux" && process.cwd().startsWith("/mnt/");

const cacheDir = startedFromWslOnWindowsDrive
    ? "/tmp/vite-cache-catchup"
    : undefined;   // undefined keeps Vite's default, node_modules/.vite

// The JSX plugin compiles JSX straight to Vue's h(), so no window.React shim
// is needed here (the lab needed one only because it served React and Vue
// from the same source tree).
export default defineConfig({
    cacheDir,
    plugins: [vueJsxPlugin()],
    server: {
        host: "localhost",
        port: 8080,
        watch: {
            // The project lives on the Windows filesystem. When the dev server
            // is started from WSL, /mnt/c does not deliver inotify events, so
            // without polling nothing hot-reloads and you end up debugging a
            // stale bundle. Harmless when running natively on Windows.
            usePolling: true,
            interval: 300,
        },
    },
    build: {
        target: "esnext",
        sourcemap: true,
        minify: false,
    },
    test: {
        environment: "happy-dom",
        clearMocks: true,
        css: false,
    },
});
