'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"version.json": "85ae83f7df2995c6cb9646d6e4b6b02a",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"manifest.json": "daa24f9c913dae2c282ec526e52e6749",
"assets/fonts/MaterialIcons-Regular.otf": "56dc6afcec1293356a60a68808063bda",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/assets/data/body.json": "4d9b17b50d04fe1ce35f64f1df8563a9",
"assets/assets/data/food.json": "706bd60099e33e254334703cbd3085a3",
"assets/assets/data/miscellaneous.json": "0fed9dc63de3577b2d7acdd31d9ea381",
"assets/assets/data/home.json": "3e85c7b204c5c48af90928a21c7a202e",
"assets/assets/data/electronics.json": "c5deedcc1f312738d03f4f4f785e96dc",
"assets/assets/data/locations.json": "ac42a90c3aed8eb87fb33a041af3292d",
"assets/assets/data/time.json": "8184efb2dfa0f249172c17bb7bde6f40",
"assets/assets/data/directions.json": "187d354bccc3c686dc62fdc207a8a6e0",
"assets/assets/data/numbers.json": "9646a45df247fcfc0937ce7e7cc4e19b",
"assets/assets/data/pronouns.json": "96e5c6f8ed18dc2f8e85580ac1dd7476",
"assets/assets/data/topics.json": "cdc06ea832ce12dc216584bdcd0b1878",
"assets/assets/data/verbs.json": "a195a6f87786a3a1309ae77f95c49344",
"assets/assets/data/clothing.json": "a3d85109d717a9b91e0eeb9ca43c0e87",
"assets/assets/data/people.json": "817beb0162ff7423caff792a9182ac55",
"assets/assets/data/society.json": "5366d9b49b1620822e31778ba0ddbdc7",
"assets/assets/data/nature.json": "b741713364ad6bf9bb124fff94300b07",
"assets/assets/data/math.json": "41bc8fc1895f788d689dd10683c345b4",
"assets/assets/data/materials.json": "545bbd1402dd77403cae95b5658fbf08",
"assets/assets/data/art.json": "9fa6425db9c5c2736e3fc8067f098cc0",
"assets/assets/data/days.json": "e6b973b4ca5f0cd8641c79cb735292d3",
"assets/assets/data/adjectives.json": "e08fe5b7fef3b7ac4fec5bb50a7050b0",
"assets/assets/data/transportation.json": "f46e3d6f7f3b832ee1db290729bdec12",
"assets/assets/data/beverages.json": "7ef81abf2d6c59bfbb5dc78c31a72b74",
"assets/assets/data/months.json": "993cd7ed093f5630905b032c9e569010",
"assets/assets/data/animals.json": "1fcc7613155c2a11b3c61f4cb2dec42f",
"assets/assets/data/jobs.json": "0f4da9bc3c8989070aaddcb6790c39ef",
"assets/AssetManifest.bin": "8ff8c008abf6d58df5711d8ea885a9fb",
"assets/AssetManifest.json": "f413078e596c9ead1f148d4b5ef2e2c5",
"assets/NOTICES": "169927fb372f6442d5548faa5ef91854",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "0d0a8b1fef1a7f82b7d1a417871b3f0c",
"main.dart.js": "898f2b7da7c32ae6bccd518af1708662",
"index.html": "7a378a93f2236db9ebfc6d3ac5fd7801",
"/": "7a378a93f2236db9ebfc6d3ac5fd7801",
"flutter_bootstrap.js": "c27330bb23cb7e047f645b7dd25bcadb",
"CNAME": "dd90350723b70d7cc2099ee415f3a2f9",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
