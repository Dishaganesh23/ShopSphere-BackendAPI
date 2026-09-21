[README.md](https://github.com/user-attachments/files/32459747/README.md)
# ShopSphere Backend API — Person C

## Setup (Day 3)

```bash
cd backend-api
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Open **http://localhost:8000/docs** — this is your auto-generated API
documentation. Share this URL with Person D.

## What's already done (Day 4–6, in one file)

- All 6 endpoints from `api-contract.md`, returning realistic mock JSON
  in the exact shape the contract specifies.
- `/ws/live-updates` WebSocket pushing a fake `new_order` event every 3
  seconds.
- CORS enabled so the React dev server can call this locally.

## Test it manually

```bash
curl http://localhost:8000/api/revenue
curl http://localhost:8000/api/active-users
curl "http://localhost:8000/api/orders?limit=3"
curl "http://localhost:8000/api/top-products?limit=5"
curl "http://localhost:8000/api/user-activity?product_id=P-2003"
curl "http://localhost:8000/api/recommendations?product_id=P-2003"
```

For the WebSocket, easiest is the browser console on any page, or a tool
like `websocat`:

```bash
websocat ws://localhost:8000/ws/live-updates
```

## Day 7 — before the Week 1 sync

- [ ] Confirm `/docs` loads and every endpoint is listed
- [ ] Demo the WebSocket pushing updates live
- [ ] Double check every field name/type still matches `api-contract.md`
      exactly — if you changed anything while building, update the
      contract file FIRST and tell the team

## Week 2 — swapping in real data

Each endpoint function in `main.py` currently returns mock data. When
Person B's databases are live, replace the body of each function with
the real query — keep the function signature and returned dict shape
identical so Person D's frontend never has to change.

| Endpoint | Week 2 real source |
|---|---|
| `/api/revenue` | Redis (fast counter) or aggregate from Mongo |
| `/api/orders` | MongoDB, most recent N orders |
| `/api/active-users` | Redis counter |
| `/api/top-products` | MongoDB aggregation or Cassandra |
| `/api/user-activity` | Cassandra (click logs) + Mongo (orders) |
| `/api/recommendations` | Neo4j Cypher query |
| `/ws/live-updates` | Triggered by the stream processor (Person B) on each new Kafka event, instead of the `asyncio.sleep` loop |
