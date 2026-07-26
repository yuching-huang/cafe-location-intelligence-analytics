{{ 
    config(
        materialized='view'
    )
}}
-- this is local config, global config is in dbt_project.yml

SELECT
    raw_data:id::STRING AS cafe_id,
    raw_data:displayName.text::STRING AS cafe_name,
    raw_data:rating::FLOAT AS rating,
    raw_data:userRatingCount::NUMBER AS review_count,
    raw_data:priceLevel::STRING AS price_level,
    raw_data:primaryType::STRING AS primary_type,
    raw_data:types AS types_raw,
    raw_data:formattedAddress::STRING AS formatted_address,
    raw_data:location.latitude::FLOAT AS latitude,
    raw_data:location.longitude::FLOAT AS longitude,
    raw_data:regularOpeningHours.weekdayDescriptions AS weekday_descriptions,
    raw_data:regularOpeningHours.periods AS opening_periods,
    raw_data:parkingOptions AS parking_options,
    raw_data:servesBreakfast::BOOLEAN AS serves_breakfast,
    raw_data:servesBrunch::BOOLEAN AS serves_brunch,
    raw_data:servesLunch::BOOLEAN AS serves_lunch,
    raw_data:servesDinner::BOOLEAN AS serves_dinner,
    raw_data:servesDessert::BOOLEAN AS serves_dessert,
    raw_data:servesCoffee::BOOLEAN AS serves_coffee,
    raw_data:servesVegetarianFood::BOOLEAN AS serves_vegetarian_food,
    search_neighborhood,
    source,
    batch_id,
    ingested_at
FROM {{ source('raw', 'raw_google_places_cafes') }}