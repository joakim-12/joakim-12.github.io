const CACHE_NAME = "campus-connect-v45";
const MEDIA_CACHE_NAME = "campus-connect-media-v1";
const MAX_MEDIA_ENTRIES = 240;
const APP_SHELL = [
    "/",
    "/messages.html",
    "/classes.html",
    "/universities.html",
    "/manifest.json",
    "/icons/icon-192.png",
    "/icons/icon-512.png",
    "/icons/icon-192-maskable.png",
    "/icons/icon-512-maskable.png"
];
const APP_PAGES = new Set(["/", "/messages.html", "/classes.html", "/universities.html"]);

function isSupabaseMedia(url) {
    return /^https?:$/.test(url.protocol) &&
        url.hostname.endsWith(".supabase.co") &&
        url.pathname.includes("/storage/");
}

async function trimMediaCache(cache) {
    const keys = await cache.keys();
    if (keys.length <= MAX_MEDIA_ENTRIES) return;
    const excess = keys.length - MAX_MEDIA_ENTRIES;
    await Promise.all(keys.slice(0, excess).map((key) => cache.delete(key)));
}

async function cacheMedia(event, request, url) {
    // Store under the token-free path so a rotated signed URL still hits.
    const stableKey = new Request(`${url.origin}${url.pathname}`, {
        mode: request.mode === "no-cors" ? "no-cors" : "cors",
        credentials: "omit"
    });
    const cache = await caches.open(MEDIA_CACHE_NAME);
    const cached = await cache.match(stableKey) || await cache.match(request);
    if (cached) return cached;

    try {
        const response = await fetch(request);
        if (response.ok || response.type === "opaque") {
            event.waitUntil(
                cache.put(stableKey, response.clone())
                    .then(() => trimMediaCache(cache))
            );
        }
        return response;
    } catch {
        const fallback = await cache.match(stableKey);
        return fallback || Response.error();
    }
}

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

    // Supabase-hosted media (avatars, public chat photos, voice notes) is
    // served from another origin. Cache the stable path so it survives
    // even when the signed token in the query string rolls over.
    if (isSupabaseMedia(url)) {
        event.respondWith(cacheMedia(event, request, url));
        return;
    }

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
