- [X] Use tachyons locally
- [X] ExtractText css
- [X] Minimize css
- [X] Leaflet css?
- [X] URL for font?
  - [ ] investigate with s/w
- [ ] Serve fonts locally?

- [X] Critical css?
- [X] Shell and css

- [X] Do not copy css folder into dist any more
- [ ] Check asset caching with s/w
- [ ] Delayed loading spinner?

- [LATER] Remove unused css
  - [ ] maybe with the new penthouse, or manually

- [ ] Remove console logs with babel loader transform?

- [ ] App shell?
- [ ] Analyse bundle size
- [ ] Separate index.js?
- [ ] babel-polyfill and runtime?
- [ ] Promise polyfill (or use lie, since pouchdb uses it)?
- [ ] whatwg-fetch polyfill check
- [ ] Update readme with new npm scripts
- [ ] Caching considerations
- [ ] lazy-load leaflet on shouldshowmap?
- [ ] Are the name plugins necessary?

- [X] SW script compression
- [X] Add anki export to additional cache instead of main
- [X] Webpack separate runtime
- [X] Vendor bundle
- [X] lazy-load anki stuff
- [X] Compile separate modules and nomodules
  - Tested, not much difference (I guess leaflet and Pouchdb-browser already compiled)
    - [] Check later if we can recompile them
