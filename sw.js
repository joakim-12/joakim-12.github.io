const CACHE_NAME = "campus-connect-1.31";
const MEDIA_CACHE_NAME = "campus-connect-media-v1";
/* The app is a library now, not a viewer: statuses, stories and chat media
   stay readable on a bus with no network. The pile is bounded by count and
   by bytes, and a file that gets used moves to the fresh end, so eviction
   trims the forgotten ones instead of the one opened every morning. */
const MAX_MEDIA_ENTRIES = 700;
const MAX_MEDIA_BYTES = 400 * 1024 * 1024;

/* Inside the APK the pages, scripts and icons are already baked into the app
   bundle, so caching them here would only risk serving a stale build after an
   overwrite install. The Capacitor asset host is always localhost with no port;
   a dev or preview server on localhost always has one. */
const IS_APK = self.location.hostname === "localhost" && !self.location.port;
const APP_SHELL = [
    "/",
    "/messages.html",
    "/classes.html",
    "/universities.html",
    "/companies.html",
    "/services.html",
    "/bulletin/news.json",
    "/manifest.json",
    "/icons/icon-192.png",
    "/icons/icon-512.png",
    "/icons/icon-192-maskable.png",
    "/icons/icon-512-maskable.png"
];
const APP_PAGES = new Set(["/", "/messages.html", "/classes.html", "/universities.html", "/companies.html", "/services.html"]);

function isSupabaseMedia(url) {
    return /^https?:$/.test(url.protocol) &&
        url.hostname.endsWith(".supabase.co") &&
        url.pathname.includes("/storage/");
}

let lastByteTrimAt = 0;

async function trimMediaCache(cache) {
    const keys = await cache.keys();          // oldest first; a touch re-appends
    const overCount = Math.max(keys.length - MAX_MEDIA_ENTRIES, 0);
    const doomed = keys.slice(0, overCount);  // the forgotten head dies first
    const now = Date.now();
    /* The byte pass reads every surviving response, so it runs on a clock,
       not on every put: a scrolling feed should not spend its battery
       weighing its own library. Sizes come from response.size, which the
       engine knows even for no-cors copies that cannot read headers. */
    if (now - lastByteTrimAt >= 30000) {
        lastByteTrimAt = now;
        const survivors = keys.slice(overCount);
        const responses = await Promise.all(survivors.map((key) => cache.match(key)));
        let bytes = 0;
        for (let index = survivors.length - 1; index >= 0; index -= 1) {
            const size = responses[index] ? responses[index].size : 0;
            if (bytes + size > MAX_MEDIA_BYTES) doomed.push(survivors[index]);
            else bytes += size;
        }
    }
    if (doomed.length) await Promise.all(doomed.map((key) => cache.delete(key)));
}

async function touchMedia(cache, key, copy) {
    // A touch keeps the count where it was, so it never needs to trim.
    await cache.delete(key);
    return cache.put(key, copy);
}

async function cacheMedia(event, request, url) {
    // Store under the token-free path so a rotated signed URL still hits.
    const stableKey = new Request(`${url.origin}${url.pathname}`, {
        mode: request.mode === "no-cors" ? "no-cors" : "cors",
        credentials: "omit"
    });
    const cache = await caches.open(MEDIA_CACHE_NAME);
    const stableMatch = await cache.match(stableKey);
    const cached = stableMatch || await cache.match(request);
    if (cached) {
        // A used file is a kept file: re-insert it at the fresh end.
        event.waitUntil(touchMedia(cache, stableMatch ? stableKey : request, cached.clone()));
        return cached;
    }

    try {
        const response = await fetch(request);
        if (response.ok || response.type === "opaque") {
            event.waitUntil(
                cache.put(stableKey, response.clone())
                    .then(() => trimMediaCache(cache))
            );
        }
        return response;
        /* The name below is never read, and it still has to be there: a `catch`
           with no binding is ES2019, and this file is copied as it is instead of
           bundled down, so an older WebView would refuse to parse it and the app
           would quietly lose the offline half a student on a bad network needs. */
        // eslint-disable-next-line no-unused-vars
    } catch (cacheMiss) {
        const fallback = await cache.match(stableKey);
        return fallback || Response.error();
    }
}

/* A tapped tab that is already in the phone should show the phone's own
   copy at once, with the network copy read behind it for the next visit.
   Making the finger wait for a round trip before anything paints is
   exactly the pause this removes. Only the served site comes here; the
   APK returned above already reads from its bundle. */
function navigateFast(event, request, url) {
    const revalidation = fetch(request)
        .then((response) => {
            if (!response.ok) return response;
            const copy = response.clone();
            return caches.open(CACHE_NAME)
                .then((cache) => cache.put(url.pathname, copy))
                .then(() => response);
        })
        .catch(() => null);
    event.waitUntil(revalidation.then(() => null));
    return caches.open(CACHE_NAME).then((cache) =>
        cache.match(url.pathname).then((cached) => cached ||
            revalidation.then(async (fresh) => fresh ||
                (await cache.match("/")) || Response.error())));
}

function freshWithFallback(event, request, url) {
    return fetch(request).then((response) => {
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
    });
}

self.addEventListener("install", (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => IS_APK ? null : cache.addAll(APP_SHELL))
            .then(() => self.skipWaiting())
    );
});

self.addEventListener("activate", (event) => {
    event.waitUntil(
        caches.keys()
            .then((keys) => Promise.all(
                keys
                    .filter((key) => key.startsWith("campus-connect-")
                        && key !== CACHE_NAME
                        // The downloaded statuses and chat media outlive a build,
                        // so a version bump must not throw them away.
                        && key !== MEDIA_CACHE_NAME)
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

    // Everything else inside the APK is read straight from the app bundle.
    if (IS_APK) return;

    if (url.origin !== self.location.origin) return;

    if (request.mode === "navigate") {
        // The six app pages answer from the pocket; anything else still
        // goes to the network first and to the cache only when it fails.
        event.respondWith(APP_PAGES.has(url.pathname) ?
            navigateFast(event, request, url) :
            freshWithFallback(event, request, url));
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
