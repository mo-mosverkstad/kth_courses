# Catch Up! — Vue implementation

Meeting space planner. Vue 3 + Redux Toolkit, Model-View-Presenter.

## Running it

Node is required. On this machine it is installed under WSL via nvm, and the
project lives on the Windows filesystem, so run it from WSL:

```bash
export PATH="$HOME/.nvm/versions/node/v24.16.0/bin:$PATH"
cd dh2642_interaction_programming
npm install
npm run dev        # http://localhost:8080
npm test           # 30 tests
npm run build
```

The lab's own dev server also defaults to port 8080. If it is running, pass
`--port 8123` or stop the other one first.

## Why Redux and not Recoil

Recoil is React-only — it depends on React's scheduler, so it cannot drive a
Vue render. For Vue the realistic A-grade state managers are Pinia/Vuex or
Redux. Redux Toolkit was chosen because the A-plus criterion rewards
*"framework-independent Redux mappings (connect) instead of custom hooks"*,
which is exactly what `src/vueRedux/connect.js` provides.

## Architecture

Four concerns, never mixed. The dependency direction is asserted by tests in
`src/__tests__/architecture.test.js`, so a violation fails the build rather
than surviving to the examination.

```
src/
├── api/                 EXTERNAL DATA ONLY — fetch + normalise, nothing else
│   ├── placeSource.js       Overpass (spaces) + Nominatim (geocoding)
│   ├── transitSource.js     Resrobot, with a distance fallback
│   └── weatherSource.js     Open-Meteo
│
├── persistence/         PERSISTENCE ONLY — the only place Firebase exists
│   ├── firebase.js          init, collection names
│   ├── authPersistence.js   sign in/up/out, per-user defaults
│   ├── meetupPersistence.js reads, writes, live onSnapshot subscriptions
│   └── plainify.js          Firestore Timestamp -> plain millis
│
├── model/               APPLICATION STATE ONLY
│   ├── store.js             configureStore + listener middleware
│   ├── actions.js           intentions a presenter may dispatch
│   ├── sideEffects.js       ** every side effect in the app lives here **
│   ├── scoring.js           pure ranking + explanation logic
│   ├── selectors.js         everything derived
│   └── slices/              auth, meetup, requests, ui, forms
│
├── vueRedux/
│   └── connect.js           the only file that knows about both Vue and Redux
│
├── presenters/          PRESENTER ONLY — two mappings + which view to show
└── views/               VIEW ONLY — props in, callbacks out, one role each
```

### The rules that are actually enforced

- A **view** never imports the store, the model, Firebase, an API source, or the
  router. It receives props and reports through callback props.
- A **presenter** is `connect(mapStateToProps, mapDispatchToProps)(View)`. It
  contains no markup, no fetch, no persistence and no component state. Where it
  needs to pick between a loading, error, empty or content view, it does only
  that.
- **All side effects go through the state manager.** `sideEffects.js` is the
  single wiring point: it listens for intentions and performs the fetching,
  the persistence, the live subscriptions and the file download. No presenter
  event handler ever calls Firebase or `fetch`.
- **Form contents live in application state** (`slices/formsSlice.js`), not in
  component state.
- **The route is application state** (`ui.route`). Presenters read it from the
  store, not from the router.
- **The breakpoint is application state** (`ui.breakpoint`), measured once in
  `index.jsx`. No component contains a media query.

### How a user gesture flows

```
view callback prop
   -> presenter dispatches ONE intention          (model/actions.js)
      -> listener in sideEffects.js performs the work
         -> api/ or persistence/ module called
            -> result dispatched back as a slice action
               -> selectors recompute
                  -> connect re-maps and the view re-renders
```

## Data model

One document per user per concern. This is what makes simultaneous editing
safe, and `firestore.rules` enforces it rather than relying on hidden buttons.

```
catchupUsers/{uid}                        displayName, defaults
catchupMeetups/{id}                       title, purpose, organizerId,
                                          inviteCode, status, windows,
                                          memberIds[], confirmedOptionId
catchupMeetups/{id}/participants/{uid}    startingArea, maxTravelMinutes, needs
catchupMeetups/{id}/availability/{uid}    intervals[]
catchupMeetups/{id}/options/{optionId}    space, window, travel, weather  (API cache)
catchupMeetups/{id}/votes/{uid}           optionIds[]
catchupMeetups/{id}/activity/{eventId}    append-only log
```

Deploy the rules before any real use:

```bash
firebase deploy --only firestore:rules
```

## External APIs

| Source | Used for | Key |
|---|---|---|
| Overpass (OpenStreetMap) | candidate spaces + facility tags | none |
| Nominatim (OpenStreetMap) | geocoding a typed starting area | none |
| Open-Meteo | weather at the proposed time | none |
| Trafiklab Resrobot | public transport travel time per member | **required** |

Three of the four work with no key, so the mash-up runs out of the box. For
real travel times, register at trafiklab.se and set `RESROBOT_KEY` in
`src/apiConfig.js`. Without it `transitSource.js` falls back to a
distance-based estimate and every affected number is labelled "estimated from
distance" in the interface — the data degrades, the app does not break.

If Resrobot turns out to be unreachable from the browser, route it through the
course proxy; only `transitSource.js` changes.

## Scoring

`model/scoring.js` is pure, so the explanation shown in the UI is generated
from the same numbers that produce the ranking. A test asserts that the cost
equals the sum of the displayed penalties, which is what stops the explanation
drifting from the real reason.

```
cost = meanTravel
     + 0.7 x maxTravel          <- punishes "fine on average, bad for one person"
     + 25  x membersUnavailable
     + accessibilityPenalty     <- a missing OSM tag is NOT treated as a yes
     + openingHoursPenalty
     + weatherPenalty

suitability = cost scaled to 0-100 against the best and worst option found
```

"Weigh fairness higher" doubles the `maxTravel` weight. It is a user control
over the model, not a second model.

## Responsive layout

One component set, three arrangements, driven by `ui.breakpoint`:

| | phone `<600` | tablet portrait `600-1023` | wide `>=1024` |
|---|---|---|---|
| Navigation | bottom tabs | left icon rail | labelled sidebar |
| Options | map/list tabs | map above list | three panes, no navigation |
| Cards per row | 1 | 2 | 3 |

Type scale, colours, copy and component shapes are identical at every width.

## Tests

```
src/model/__tests__/scoring.test.js     18  ranking, fairness, missing data
src/model/__tests__/selectors.test.js    3  per-member rows, never an average
src/__tests__/architecture.test.js       9  the layer boundaries above
```

The architecture tests read the source and check which layers import which.
They are the ones worth keeping green, because separation of concerns is the
criterion that is hardest to repair late.

## State of the implementation

Verified:

- `npm run build` succeeds, 104 modules, no warnings that matter
- all 30 tests pass
- the app mounts and renders in a real browser with no Vue warnings and no
  uncaught exceptions

Not yet verified, and the first thing to do next:

- the signed-in flows end to end (create, invite, availability, option
  building, voting, confirm, live sync across two browsers). These need real
  Firebase credentials and network reach to Google, Overpass and Open-Meteo,
  which could not be exercised in the environment this was written in.
- Resrobot has never been called with a real key.
- Firestore rules are written but not deployed or tested against.

## Known gaps

- The bundle is 2.3 MB unminified because `minify: false` is kept for
  examination. Turn it on for deployment.
- `closesBefore` in `scoring.js` reads only simple `opening_hours` values and
  reports "unknown" for anything else, by design.
- A space's `opening_hours` is only read in the simple case; anything else is
  reported as "hours unknown" rather than guessed.
- `DEFAULT_AREA` in `apiConfig.js` is now only a fallback for the error
  message. The real search area comes from `model/candidates.js`.

## Where the search looks

`model/candidates.js` decides this, and it is pure so it is covered by tests.

`groupArea(participants)` centres the Overpass query on the **centroid of the
participants' starting coordinates**, with a radius of their spread plus 1.5 km
(floor 1.2 km, ceiling 12 km). Moving one member's starting area moves the
search. If nobody has entered a starting area, option building refuses with an
explanation instead of silently searching a default point.

`shortlistSpaces(...)` then picks the 8 to spend API calls on: nearest first,
but with hard per-category caps so one plentiful category cannot fill the list.
For a meeting that is at most 3 cafes, 3 libraries and 2 coworking spaces; a
study session shifts the weight to libraries. If the caps leave fewer than 8,
the list stays short on purpose, because eight cafes are not eight decisions.
Caps are only relaxed to avoid returning fewer than three options.

The Options screen states the area it searched and its radius, so an unexpected
result is attributable instead of mysterious.
