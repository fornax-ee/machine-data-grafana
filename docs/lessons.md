# Lessons

## Data model

- **Narrow beats wide.** One row per value (`ts, line, device, signal, value`) survives new sensors and new machines without schema changes. Wide tables (one column per sensor) break every time the line changes.
- **Tags for context.** Recipe and order number on the row make later analysis possible ("is the drift tied to one recipe?").
- **Name signals with units.** `temp_c`, `base_g`, `speed_m_min`. Unit confusion is the most common analysis error.
- **UTC in the database,** local time in Grafana.

## Collection

- Sample at the rate the process changes, not the rate the PLC allows. Most line signals are fine at 1–10 s; event-based signals (start/stop, alarm) are logged on change.
- Buffer locally when the database is unreachable; production data should not be lost because of a network hiccup.
- Prefer **MQTT** or **OPC UA** where available. Raw TCP socket integrations work but are more fragile to reconnects.
- The collector is read-only towards the machine. Writing setpoints back is a different project with different risk.

## OEE basics

```
OEE = Availability × Performance × Quality
Availability = run time / planned production time
Performance  = (ideal cycle time × total count) / run time
Quality      = good count / total count
```

Start with **availability** from a single `running` signal; it is the easiest to get and usually the biggest loss. Add counts later.

## Dashboards

- One dashboard per question, not one per machine. "Is the ratio stable?" beats "Robot 1 overview".
- Show the target and tolerance on the same chart as the actual value. A number without a target is just a number.
- Alerts only on things someone will act on, during working hours, routed to the people who own the line.

## Pitfalls

- Counters that reset (PLC restart) create negative deltas; handle resets in the query.
- Duplicate timestamps from reconnecting collectors; add a unique constraint or deduplicate in the query.
- Grafana with a writable database user. Always use a read-only role.
