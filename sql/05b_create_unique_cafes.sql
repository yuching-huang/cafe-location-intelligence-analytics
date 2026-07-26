USE WAREHOUSE cafe_wh;
USE DATABASE cafe_location_intelligence;
USE SCHEMA staging;

CREATE OR REPLACE VIEW stg_unique_cafes AS
SELECT
    cafe_id,
    ANY_VALUE(cafe_name) AS cafe_name,
    ANY_VALUE(rating) AS rating,
    ANY_VALUE(review_count) AS review_count,
    ANY_VALUE(price_level) AS price_level,
    ANY_VALUE(primary_type) AS primary_type,
    ANY_VALUE(types_raw) AS types_raw,
    ANY_VALUE(formatted_address) AS formatted_address,
    ANY_VALUE(latitude) AS latitude,
    ANY_VALUE(longitude) AS longitude,
    ANY_VALUE(weekday_descriptions) AS weekday_descriptions,
    ANY_VALUE(opening_periods) AS opening_periods,
    ANY_VALUE(parking_options) AS parking_options,

    ANY_VALUE(serves_breakfast) AS serves_breakfast,
    ANY_VALUE(serves_brunch) AS serves_brunch,
    ANY_VALUE(serves_lunch) AS serves_lunch,
    ANY_VALUE(serves_dinner) AS serves_dinner,
    ANY_VALUE(serves_dessert) AS serves_dessert,
    ANY_VALUE(serves_coffee) AS serves_coffee,
    ANY_VALUE(serves_vegetarian_food) AS serves_vegetarian_food,

    LISTAGG(
        DISTINCT search_neighborhood,
        ', '
    ) AS found_in_neighborhoods,

    MAX(ingested_at) AS latest_ingested_at

FROM cafe_location_intelligence.staging.stg_google_places_cafes

WHERE cafe_id IS NOT NULL

GROUP BY cafe_id;