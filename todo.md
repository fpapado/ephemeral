- [X] Use tachyons locally
- [X] ExtractText css
- [X] Minimize css
- [X] Leaflet css?
- [X] URL for font?
- [X] Critical css?
- [X] Shell and css
- [X] Do not copy css folder into dist any more
- [X] Check asset caching with s/w
- [X] App shell?

- [ ] make SVG out of logo, inline it

- [ ] Remove console

- [ ] Scope hoisting

- [ ] Try babily?

- [ ] Serve font async / non-blocking
  - locally?
  - currently import(..) in critical CSS blocks
  - https://github.com/bramstein/fontfaceobserver
  - https://www.filamentgroup.com/lab/font-events.html
  - NOTE: Do this once fonts are settled

- [ ] Cursive font fallback
- [ ] lazy-load leaflet on shouldshowmap?
- [ ] Remove console logs with babel loader transform?

# Later
- [ ] Remove unused css
  - [ ] maybe with the new penthouse, or manually


# Probably not important
- [ ] babel-polyfill and runtime?
- [ ] Promise polyfill (or use lie, since pouchdb uses it)?
- [ ] whatwg-fetch polyfill check
- [ ] Update readme with new npm scripts
- [ ] Caching considerations
- [ ] Delayed loading spinner?

- [X] SW script compression
- [X] Add anki export to additional cache instead of main
- [X] Webpack separate runtime
- [X] Vendor bundle
- [X] lazy-load anki stuff
- [X] Compile separate modules and nomodules
  - Tested, not much difference (I guess leaflet and Pouchdb-browser already compiled)
    - [] Check later if we can recompile them
