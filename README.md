[HANDOFF.md](https://github.com/user-attachments/files/32459935/HANDOFF.md)
# Person C → Person D

## What I built

A FastAPI server (`main.py`) exposing every endpoint from `api-contract.md`,
plus a WebSocket for live updates. Right now (Week 1) every endpoint
returns realistic **mock** data in the locked contract shape, so you can
build the whole dashboard against it before the real pipeline exists.

```
GET  /api/revenue
GET  /api/orders?limit=10
GET  /api/active-users
GET  /api/top-products?limit=5
GET  /api/user-activity?product_id=...
GET  /api/recommendations?product_id=...
WS   /ws/live-updates
```

Auto-generated docs: `http://localhost:8000/docs` — open this to try every
endpoint in the browser without writing any fetch code.

## How each endpoint will map to real data (Week 2)

Based on Person B's stream-processor doc, here's what's actually behind
each endpoint once I swap the mocks for real queries — noting this now so
nobody is surprised when values behave differently than the Week 1 mock:

| Endpoint | Real source (Week 2) | Gotcha to know about |
|---|---|---|
| `/api/revenue` | Redis `orders:revenue_today` (INCRBYFLOAT) + `orders:count` | Redis value has float drift (e.g. `15876.39999999999999947`) — I round to 2 decimals server-side, so you'll always get a clean number from the API. You never need to round it yourself. |
| `/api/orders` | MongoDB `orders` collection | Product names: only `P10`–`P19` have a name in the `products` lookup collection. The producer emits IDs up to roughly `P50`, so some orders will show a raw ID instead of a name — that's expected, not a bug on your end. |
| `/api/active-users` | Redis `active_users` set (cardinality) | This is "sessions currently marked active," not a live websocket-connection count — don't expect it to move in real time between server pushes. |
| `/api/top-products` | MongoDB aggregation over `orders` (count by `product_id`) | Same P10–P19 name-lookup limit as above applies here too. |
| `/api/user-activity` | Cassandra `clicks` table (filtered by inferred product page) + Mongo orders count | `page` in Cassandra is a category label (`home`, `product_detail`, `cart`, `checkout`), not a URL — there's no direct `product_id` column on clicks yet, so per-product click counts are an approximation until B's schema adds one. Flagging this to B separately. |
| `/api/recommendations` | Neo4j Cypher query (`BOUGHT` relationships) | This is real graph data, verified working — pass a `product_id` in the `P1x`–`P5x` range to get non-empty results. |
| `/ws/live-updates` | Triggered by the stream processor as it consumes each Kafka event | In Week 1 this is a fake timer (`asyncio.sleep(3)`). In Week 2 it'll fire on actual events, so push frequency will become irregular (bursty) instead of a steady 3-second tick — don't build any UI animation that assumes a fixed interval. |

**Important, from Person B's notes:** the `timestamp` field on every event is
random fake data scattered across past and future years — do **not** build
any "last hour" / "today" trend logic off it. Anything "live" on the
dashboard is driven by *when the event was processed*, not that field. Your
API responses already reflect current processing time (`as_of`, live
WebSocket pushes), so just consume those as-is rather than the underlying
`timestamp`.

## How to run this locally

```bash
cd backend-api
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Open `http://localhost:8000/docs` to confirm all 6 endpoints + the
WebSocket are listed and respond.

Test manually:

```bash
curl http://localhost:8000/api/revenue
curl http://localhost:8000/api/active-users
curl "http://localhost:8000/api/orders?limit=3"
curl "http://localhost:8000/api/top-products?limit=5"
curl "http://localhost:8000/api/user-activity?product_id=P-2003"
curl "http://localhost:8000/api/recommendations?product_id=P-2003"
```

## Known issues / gotchas (read before debugging from scratch)

- **CORS:** currently wide open (`allow_origins=["*"]`) so your dev server
  can call this from any port. Tighten this before deployment (Week 4).
- **Mock state resets on restart:** the in-memory counters (`revenue_today`,
  `orders_today`, `active_users`) live in a plain Python dict, not a real
  database — every `uvicorn --reload` restart resets them to the starting
  values in `main.py`. This is fine for Week 1; it goes away once real
  queries replace the mocks.
- **Contract is the source of truth:** if any field name or response shape
  in `main.py` doesn't match `api-contract.md`, the contract wins — flag it
  to the team and update the file first, don't silently change either side.
- **Week 2 dependency:** once I wire in real DB calls, this server needs
  Kafka + Mongo + Cassandra + Redis + Neo4j running first (`docker compose
  up -d` from the repo root, per B's doc) — the mock version you're using
  now has zero external dependencies, which is why it's safe to build
  against before that infra exists.

## Confirmation checklist

- [ ] `/docs` loads and lists all 6 endpoints + the WebSocket
- [ ] Every response field name/type matches `api-contract.md` exactly
- [ ] WebSocket pushes a `new_order` event visibly (tested via browser
      console or `websocat ws://localhost:8000/ws/live-updates`)
- [ ] Shared base URL + `/docs` link with Person D
- [ ] Flagged the missing per-product click linkage in Cassandra to
      Person B ahead of Week 2
