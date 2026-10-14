const CACHE_NAME = "campus-connect-v15";
const APP_SHELL = [
    "/",
    "/messages.html",
    "/classes.html",
    "/manifest.json",
    "/icons/icon-192.png",
    "/icons/icon-512.png",
    "/icons/icon-192-maskable.png",
    "/icons/icon-512-maskable.png"
];
const APP_PAGES = new Set(["/", "/messages.html"]);

self.addEventListener("install", (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => cache.addAll(APP_SHELL))
            .then(() => self.skipWaiting())
    );
});

self.addEventListener("activate", (event) => {
    event.waitUntil(
        caches.keys()
            .then((keys) => Promise.all(
                keys
                    .filter((key) => key.startsWith("campus-connect-") && key !== CACHE_NAME)
                    .map((key) => caches.delete(key))
            ))
            .then(() => self.clients.claim())
    );
});

self.addEventListener("fetch", (event) => {
    const request = event.request;
    if (request.method !== "GET") return;

    const url = new URL(request.url);
    if (url.origin !== self.location.origin) return;

    if (request.mode === "navigate") {
        event.respondWith(
            fetch(request).then((response) => {
                if (response.ok && APP_PAGES.has(url.pathname)) {
                    const pageUrl = new URL(url.pathname, self.location.origin);
                    const copy = response.clone();
                    event.waitUntil(
                        caches.open(CACHE_NAME)
                            .then((cache) => cache.put(pageUrl, copy))
                    );
                }
                return response;
            }).catch(async () => {
                const cache = await caches.open(CACHE_NAME);
                return (APP_PAGES.has(url.pathname) && await cache.match(url.pathname)) ||
                    await cache.match("/") ||
                    Response.error();
            })
        );
        return;
    }

    const isAppAsset = request.destination === "script" ||
        request.destination === "style" ||
        request.destination === "image" ||
        request.destination === "font" ||
        url.pathname.startsWith("/assets/");
    if (!isAppAsset) return;

    event.respondWith(
        caches.open(CACHE_NAME).then(async (cache) => {
            const cached = await cache.match(request);
            if (cached) return cached;

            const response = await fetch(request);
            if (response.ok) {
                event.waitUntil(cache.put(request, response.clone()));
            }
            return response;
        })
    );
});
