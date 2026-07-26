WITH distance_calculations AS (
    SELECT
        c.cafe_id,
        c.cafe_name,
        n.amenity_type,
        n.nearby_place_id,
        n.nearby_place_name,

        c.latitude AS cafe_latitude,
        c.longitude AS cafe_longitude,
        n.nearby_latitude,
        n.nearby_longitude,

        HAVERSINE(
            c.latitude,
            c.longitude,
            n.nearby_latitude,
            n.nearby_longitude
        ) * 1000 AS distance_meters

    FROM {{ ref('stg_unique_cafes') }} as c
    LEFT JOIN {{ ref('stg_google_nearby_cafes') }} as n
        ON c.cafe_id = n.cafe_place_id
    WHERE n.nearby_latitude IS NOT NULL
      AND n.nearby_longitude IS NOT NULL
)

SELECT
    cafe_id,

    MIN(CASE 
        WHEN amenity_type = 'transit_station' 
        THEN distance_meters 
    END) AS nearest_transit_distance_m,

    MIN(CASE 
        WHEN amenity_type = 'parking' 
        THEN distance_meters 
    END) AS nearest_parking_distance_m,

    MIN(CASE 
        WHEN amenity_type = 'competing_cafe' 
        THEN distance_meters 
    END) AS nearest_competitor_distance_m

FROM distance_calculations
GROUP BY cafe_id