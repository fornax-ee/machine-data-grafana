# Machine Data to Grafana

A small, practical stack for logging production line data and analysing it in Grafana: collector → PostgreSQL → Grafana. Built for plants that want answers ("is the mixing ratio drifting?", "why was the line slow on Tuesday?") without buying a full MES.

## Architecture

```
 PLC / robot / sensors ──(OPC UA, MQTT, Modbus, vendor API)──► collector ──► PostgreSQL ──► Grafana
                                                                   │
                                                                   └─ one narrow time-series table
```

- **Collector:** small service per data source. Reads values, adds timestamp and tags, inserts rows. Buffers locally if the database is down.
- **PostgreSQL:** one narrow table for measurements, plus a few lookup tables. Add TimescaleDB later if volume demands it; plain PostgreSQL handles millions of rows per month fine with the right index.
- **Grafana:** dashboards and alerts, read-only database user.

## Contents

| File | What it covers |
|---|---|
| [sql/schema.sql](sql/schema.sql) | Narrow measurement table, index, read-only Grafana user |
| [sql/queries.sql](sql/queries.sql) | Grafana queries: time series, ratio with tolerance band, availability |
| [docs/lessons.md](docs/lessons.md) | What worked: data model, naming, OEE basics, pitfalls |
| [compose.yaml](compose.yaml) | PostgreSQL + Grafana with Podman or Docker for a test setup |

## Example use: two-component mixing ratio

Many finishing lines mix two or more components (e.g. base and hardener) by recipe. Logging the actual dosed amounts per robot and recipe and plotting the ratio against the recipe target with a tolerance band shows drift long before it becomes a quality problem. See `queries.sql`.

## License

MIT (code), CC BY 4.0 (docs).

Drafted with AI assistance, based on hands-on experience