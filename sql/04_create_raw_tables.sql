USE DATABASE cafe_location_intelligence;
USE SCHEMA raw;

-- batch id to help you track each API refresh later
CREATE OR REPLACE TABLE raw_google_places_cafes (
    batch_id STRING,
    raw_data VARIANT,
    search_neighborhood STRING,
    source STRING,
    ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE raw_google_nearby_places (
    batch_id STRING,
    cafe_place_id STRING,
    amenity_type STRING,
    search_radius_meters NUMBER,
    raw_data VARIANT,
    source STRING,
    ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE manual_cafe_enrichment (
    cafe_place_id STRING,
    total_seats NUMBER,
    seat_estimate_source STRING,
    parking_notes STRING,
    parking_price_text STRING,
    personal_notes STRING,
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);