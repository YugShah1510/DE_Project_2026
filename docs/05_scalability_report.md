# Phase 5: Scalability report

## Dataset, method, and validation

The large CSVs are extracted to `large_data/` and are excluded by `.gitignore`. I created a fresh `de_project_2026_phase5` database, ran `sql/01_schema.sql`, and loaded the files with `sql/02_load_data.sql` (the only path change is from `seed_data/` to `large_data/`). The 11 CSVs loaded 15,571,506 rows in total: 10 cities, 2,800 venues, 9,800 screens, 1,879,182 seats, 6,000 movies, 3,201,268 shows, 800,000 customers, 25 offers, 3,004,077 bookings, 6,016,946 booking seats, and 651,398 reviews. The loader's `expected` column still shows the original seed counts; its `actual` counts are the large-data counts above. I then applied `sql/05_indexes.sql` and refreshed planner statistics with its VACUUM/ANALYZE statements.

The timings below use PostgreSQL 17.11 on Apple ARM64, session timezone `Asia/Kolkata`, and the three-run average from `benchmarks/run_benchmark.sh`. The optimized workload is `sql/06_optimized_queries.sql`; writes ran in a transaction and rolled back. Raw plans for all 90 executions are in `../benchmarks/results/large/`. Seed comparison values are the Phase 4 optimized averages in `../benchmarks/results/optimized/summary.csv`.

The following checks returned zero violations: booked seats match the show screen; screen capacity equals its seat layout; confirmed booking ticket counts equal held seat rows; cancelled or failed bookings hold no seats; and shows do not overlap on a screen. The exclusion constraint also enforces the last rule during writes.

## Timing and target results

| Query | Optimized on seed (ms) | Optimized on large (ms) | Growth | Large target | Met? |
|---|---:|---:|---:|---:|:---:|
| R01 | 0.411 | 6.413 | 15.6× | < 250 ms | ✓ |
| R02 | 0.142 | 0.424 | 3.0× | < 5 ms | ✓ |
| R03 | 0.253 | 0.450 | 1.8× | < 5 ms | ✓ |
| R04 | 0.041 | 0.179 | 4.4× | < 5 ms | ✓ |
| R05 | 0.104 | 0.263 | 2.5× | < 5 ms | ✓ |
| R06 | 0.128 | 1.348 | 10.5× | < 5 ms | ✓ |
| R07 | 0.100 | 0.334 | 3.3× | < 250 ms | ✓ |
| R08 | 5.114 | 117.560 | 23.0× | < 5000 ms | ✓ |
| R09 | 0.013 | 0.020 | 1.5× | < 5 ms | ✓ |
| R10 | 37.490 | 487.897 | 13.0× | < 5000 ms | ✓ |
| R11 | 48.904 | 836.746 | 17.1× | < 5000 ms | ✓ |
| R12 | 117.834 | 1580.486 | 13.4× | < 5000 ms | ✓ |
| R13 | 0.108 | 0.145 | 1.3× | < 250 ms | ✓ |
| R14 | 4.886 | 46.137 | 9.4× | < 5000 ms | ✓ |
| R15 | 35.514 | 264.285 | 7.4× | < 5000 ms | ✓ |
| R16 | 18.147 | 408.466 | 22.5× | < 5000 ms | ✓ |
| R17 | 0.359 | 3.276 | 9.1× | < 250 ms | ✓ |
| R18 | 43.677 | 767.327 | 17.6× | < 5000 ms | ✓ |
| R19 | 0.335 | 0.597 | 1.8× | < 5000 ms | ✓ |
| R20 | 6.196 | 52.964 | 8.5× | < 5000 ms | ✓ |
| R21 | 46.144 | 2937.902 | 63.7× | < 5000 ms | ✓ |
| R22 | 6.521 | 7.088 | 1.1× | < 250 ms | ✓ |
| R23 | 0.024 | 0.226 | 9.4× | < 5 ms | ✓ |
| R24 | 64.933 | 994.245 | 15.3× | < 5000 ms | ✓ |
| R25 | 22.968 | 212.636 | 9.3× | < 5000 ms | ✓ |
| W01 | 0.932 | 1.406 | 1.5× | < 5 ms | ✓ |
| W02 | 11.279 | 0.724 | 0.1× | < 5 ms | ✓ |
| W03 | 0.463 | 0.476 | 1.0× | < 5 ms | ✓ |
| W04 | 0.112 | 0.757 | 6.8× | < 250 ms | ✓ |
| W05 | 2.134 | 5.602 | 2.6× | < 250 ms | ✓ |

All 30 queries meet the stated target. R21 is the slowest at 2937.902 ms, within the 5,000 ms analytics limit. The 5 ms real-time target applies to R02, R03, R04, R05, R06, R09, R23, W01, W02, and W03. Interactive queries have a 250 ms limit; analytics queries have a 5,000 ms limit. The exact three-run times, medians, ranges, and scan nodes are recorded in the summary CSV.

## Growth analysis

Most point lookups stayed well below their latency targets as row counts grew roughly 20×: R02–R05, R09, R13, R19, R22, R23, and W02–W04 use selective B-tree probes or small filtered sets. Their cost grows mainly with index depth and the number of matching rows. R06 scans only the 6,000-row movies table and remains 1.348 ms.

Broad reports grew with the data they must read. R11, R12, R14–R16, R18, R20, R21, and R24 scan or aggregate large portions of bookings, shows, reviews, or booking seats. R21 grew the most, from 46.144 ms to 2937.902 ms (63.7×), because the grouping touches the much larger confirmed-booking population. Its plan uses the confirmed-customer index but still processes the broad qualifying set. R08 and R16 grew around the dataset scale while staying below target. R01 and R10 are interactive/reporting cases whose elapsed time reflects their wider date ranges and larger show population; both remain inside the 250 ms and 5,000 ms targets respectively.

No query missed its target, so no large-data-specific query rewrite was needed. Full scans for broad analytics are expected when most rows contribute; further speedups would require workload changes such as maintained aggregates, with freshness and write-cost tradeoffs.

## Storage

After index creation and ANALYZE, the fresh large database used 3,167,172,275 bytes (about 3,020.5 MiB). The BMS relations used 1,112,834,048 bytes of heap and 2,045,181,952 bytes of indexes (31 indexes total), about 1.04 GiB and 1.90 GiB respectively. The largest tables were shows (936 MiB total; 212 MiB heap, 724 MiB indexes), bookings (907 MiB; 338 MiB heap, 569 MiB indexes), and booking_seats (717 MiB; 300 MiB heap, 417 MiB indexes).

Phase 4 recorded 55,590,912 bytes (about 53.0 MiB) of added index storage on the seed database. It did not retain a full seed database-size or complete heap/index split measurement, so a like-for-like total-size comparison is unavailable. The large index footprint is substantial relative to heap and should be included in storage capacity planning.

## Design for 100× volume

### Partitioning

A practical first step is hash partitioning `booking_seats` by `show_id` into 16 partitions, because seat-layout, sales, and occupancy work commonly filters by show. The partition key is included in the existing uniqueness key `(show_id, seat_id)`, which satisfies PostgreSQL's requirement that a partitioned table's primary/unique key include all partition-key columns. The illustrative DDL is in [`sql/08_partitioning.sql`](../sql/08_partitioning.sql). I validated the DDL in a rolled-back transaction: `EXPLAIN` for `show_id = 144446` visited only `booking_seats_p00` and its primary-key index. Queries that aggregate all shows still read all partitions. Production migration must preserve the no-duplicate-seat invariant and be rehearsed with the full workload.

### Sharding

Shard bookings and booking_seats by show ownership (or the show’s venue/city mapping) so one booking transaction and seat lock stay on one shard. Customer booking history (R05) and customer booking analytics (R12, R21) become cross-shard unless customer ID is also colocated; choose one access pattern as primary and use a routing directory or replicated customer dimension. Box-office and regional reports (R08, R11, R16, R18, R19, R24, R25) span cities, so run partial aggregates on each shard and merge results centrally. Cross-city show searches and cinema dashboards also scatter unless routed by city. Sharding needs globally unique booking identifiers and a strategy for cross-shard offer and customer constraints.

### Read replicas and caching

Send broad, read-only analytics (R08, R11, R12, R14–R16, R18–R21, R24–R25) to read replicas, accepting replica lag. Cache movie search and stable catalog/showtime responses (R01, R02, R06) with short expirations and invalidate near show or pricing changes. Seat availability (R03), booking lookup/history (R04, R05), and pending-payment/seat-lock work (R09, W01–W04) must use the primary or a consistency-aware path; do not cache seat inventory in a way that permits double-selling. W05 price updates also go to the primary.

### Maintenance

Use autovacuum settings tuned for the high-churn `booking_seats` table, monitor dead tuples and vacuum lag, and keep statistics current. Archive or detach old show/booking partitions only after retention and foreign-key behavior are defined. Refresh summary tables on an explicit schedule and report their data freshness. Recheck index size and write amplification as volume grows; the measured large indexes already occupy about 1.9 GiB.

## Conclusion

The optimized workload met all 30 Phase 5 latency targets on the supplied large dataset, and the integrity checks passed. This supports the current design at the tested scale on this machine. It does not prove readiness for 100× volume or production concurrency: broad reports grow with scanned rows, index storage is large, and the tests measure single-session query latency rather than concurrent throughput.
