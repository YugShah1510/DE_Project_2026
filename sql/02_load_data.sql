\set ON_ERROR_STOP on
SET search_path TO bms;

\copy cities FROM 'large_data/cities.csv' WITH (FORMAT csv, HEADER true)
\copy venues FROM 'large_data/venues.csv' WITH (FORMAT csv, HEADER true)
\copy screens FROM 'large_data/screens.csv' WITH (FORMAT csv, HEADER true)
\copy seats FROM 'large_data/seats.csv' WITH (FORMAT csv, HEADER true)
\copy movies FROM 'large_data/movies.csv' WITH (FORMAT csv, HEADER true)
\copy shows FROM 'large_data/shows.csv' WITH (FORMAT csv, HEADER true)
\copy customers FROM 'large_data/customers.csv' WITH (FORMAT csv, HEADER true)
\copy offers FROM 'large_data/offers.csv' WITH (FORMAT csv, HEADER true)
\copy bookings FROM 'large_data/bookings.csv' WITH (FORMAT csv, HEADER true)
\copy booking_seats FROM 'large_data/booking_seats.csv' WITH (FORMAT csv, HEADER true)
\copy movie_reviews FROM 'large_data/movie_reviews.csv' WITH (FORMAT csv, HEADER true)

ANALYZE;

SELECT 'cities' AS table_name, count(*) AS actual, 10 AS expected FROM cities
UNION ALL SELECT 'venues', count(*), 140 FROM venues
UNION ALL SELECT 'screens', count(*), 490 FROM screens
UNION ALL SELECT 'seats', count(*), 94056 FROM seats
UNION ALL SELECT 'movies', count(*), 300 FROM movies
UNION ALL SELECT 'shows', count(*), 160034 FROM shows
UNION ALL SELECT 'customers', count(*), 40000 FROM customers
UNION ALL SELECT 'offers', count(*), 25 FROM offers
UNION ALL SELECT 'bookings', count(*), 150094 FROM bookings
UNION ALL SELECT 'booking_seats', count(*), 300389 FROM booking_seats
UNION ALL SELECT 'movie_reviews', count(*), 32510 FROM movie_reviews;

-- Integrity checks: each query should return zero rows (except the count check).
-- 1. Every booked seat is on the screen used by its show.
SELECT bs.* FROM booking_seats bs JOIN shows sh USING (show_id)
JOIN seats se USING (seat_id) WHERE se.screen_id <> sh.screen_id;
-- Capacity values match the number of physical seat rows per screen.
SELECT sc.screen_id, sc.total_seats, count(se.seat_id) AS layout_seats
FROM screens sc LEFT JOIN seats se USING (screen_id)
GROUP BY sc.screen_id, sc.total_seats
HAVING sc.total_seats <> count(se.seat_id);
-- 2. Every confirmed booking has exactly num_tickets seat rows.
SELECT b.booking_id, b.num_tickets, count(bs.seat_id) AS held
FROM bookings b LEFT JOIN booking_seats bs USING (booking_id)
WHERE b.status = 'CONFIRMED' GROUP BY b.booking_id
HAVING count(bs.seat_id) <> b.num_tickets;
-- 3. Cancelled/failed bookings do not hold seats.
SELECT b.booking_id FROM bookings b JOIN booking_seats bs USING (booking_id)
WHERE b.status IN ('CANCELLED','PAYMENT_FAILED');
-- 4. No overlapping shows on one screen (also enforced by the exclusion constraint).
SELECT a.show_id, b.show_id FROM shows a JOIN shows b
ON a.screen_id = b.screen_id AND a.show_id < b.show_id
AND tstzrange(a.starts_at,a.ends_at,'[)') && tstzrange(b.starts_at,b.ends_at,'[)');