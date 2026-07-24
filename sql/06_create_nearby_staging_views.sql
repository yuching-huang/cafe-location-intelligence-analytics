USE WAREHOUSE cafe_wh;
USE DATABASE cafe_location_intelligence;
USE SCHEMA staging;

CREATE OR REPLACE VIEW stg_google_nearby_places AS
SELECT
    batch_id,
    cafe_place_id,
    amenity_type,
    search_radius_meters,

    raw_data:id::STRING AS nearby_place_id,
    raw_data:displayName.text::STRING AS nearby_place_name,
    raw_data:primaryType::STRING AS nearby_primary_type,
    raw_data:types AS nearby_types_raw,
    raw_data:formattedAddress::STRING AS nearby_formatted_address,
    raw_data:location.latitude::FLOAT AS nearby_latitude,
    raw_data:location.longitude::FLOAT AS nearby_longitude,
    raw_data:rating::FLOAT AS nearby_rating,
    raw_data:userRatingCount::NUMBER AS nearby_review_count,

    source,
    ingested_at

FROM cafe_location_intelligence.raw.raw_google_nearby_places;