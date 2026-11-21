-- Phase 5 illustration: hash-partition booking_seats by show_id.
-- Run in a scratch schema/database; this creates a partitioned copy structure
-- and does not replace or migrate the production bms.booking_seats table.
CREATE SCHEMA IF NOT EXISTS bms_partition_demo;

CREATE TABLE bms_partition_demo.booking_seats (
    booking_id integer NOT NULL REFERENCES bms.bookings(booking_id) ON DELETE CASCADE,
    show_id integer NOT NULL REFERENCES bms.shows(show_id) ON DELETE RESTRICT,
    seat_id integer NOT NULL REFERENCES bms.seats(seat_id) ON DELETE RESTRICT,
    price numeric(8,2) NOT NULL CHECK (price >= 0),
    PRIMARY KEY (show_id, seat_id)
) PARTITION BY HASH (show_id);

CREATE TABLE bms_partition_demo.booking_seats_p00
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 0);
CREATE TABLE bms_partition_demo.booking_seats_p01
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 1);
CREATE TABLE bms_partition_demo.booking_seats_p02
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 2);
CREATE TABLE bms_partition_demo.booking_seats_p03
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 3);
CREATE TABLE bms_partition_demo.booking_seats_p04
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 4);
CREATE TABLE bms_partition_demo.booking_seats_p05
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 5);
CREATE TABLE bms_partition_demo.booking_seats_p06
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 6);
CREATE TABLE bms_partition_demo.booking_seats_p07
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 7);
CREATE TABLE bms_partition_demo.booking_seats_p08
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 8);
CREATE TABLE bms_partition_demo.booking_seats_p09
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 9);
CREATE TABLE bms_partition_demo.booking_seats_p10
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 10);
CREATE TABLE bms_partition_demo.booking_seats_p11
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 11);
CREATE TABLE bms_partition_demo.booking_seats_p12
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 12);
CREATE TABLE bms_partition_demo.booking_seats_p13
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 13);
CREATE TABLE bms_partition_demo.booking_seats_p14
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 14);
CREATE TABLE bms_partition_demo.booking_seats_p15
    PARTITION OF bms_partition_demo.booking_seats
    FOR VALUES WITH (MODULUS 16, REMAINDER 15);

-- A constant show_id prunes this to one partition. Use EXPLAIN to inspect.
EXPLAIN (COSTS OFF)
SELECT booking_id, seat_id, price
FROM bms_partition_demo.booking_seats
WHERE show_id = 144446;
