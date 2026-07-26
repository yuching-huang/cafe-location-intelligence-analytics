USE WAREHOUSE cafe_wh;
USE DATABASE cafe_location_intelligence;

USE SCHEMA intermediate;

CREATE OR REPLACE VIEW int_cafe_nearby_features AS
SELECT
    cafe_place_id AS cafe_id,

    COUNT_IF(amenity_type = 'transit_station') AS transit_stop_count_500m,
    COUNT_IF(amenity_type = 'parking') AS parking_count_300m,
    COUNT_IF(amenity_type = 'competing_cafe') AS competing_cafe_count_500m,

    AVG(
        CASE WHEN amenity_type = 'competing_cafe' THEN nearby_rating 
        END
    ) AS avg_competitor_rating_500m,

    SUM(
        CASE WHEN amenity_type = 'competing_cafe' THEN COALESCE(nearby_review_count, 0)
        ELSE 0
        END
    ) AS competitor_review_count_500m\

FROM {{ ref('stg_google_nearby_cafes') }}
GROUP BY cafe_place_id;