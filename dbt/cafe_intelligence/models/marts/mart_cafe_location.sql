SELECT
    c.cafe_id,
    c.cafe_name,
    c.found_in_neighborhoods,
    c.rating,
    c.review_count,
    c.price_level,
    c.primary_type,
    c.formatted_address,
    c.latitude,
    c.longitude,

    c.serves_breakfast,
    c.serves_brunch,
    c.serves_lunch,
    c.serves_dinner,
    c.serves_dessert,
    c.serves_coffee,
    c.serves_vegetarian_food,

    COALESCE(n.transit_stop_count_500m, 0) AS transit_stop_count_500m,
    COALESCE(n.parking_count_300m, 0) AS parking_count_300m,
    COALESCE(n.competing_cafe_count_500m, 0) AS competing_cafe_count_500m,
    n.avg_competitor_rating_500m,
    COALESCE(n.competitor_review_count_500m, 0) AS competitor_review_count_500m,

    d.nearest_transit_distance_m,
    d.nearest_parking_distance_m,
    d.nearest_competitor_distance_m,

    /* Accessibility score */
    (
        CASE 
            WHEN COALESCE(n.transit_stop_count_500m, 0) >= 5 THEN 3
            WHEN COALESCE(n.transit_stop_count_500m, 0) >= 2 THEN 2
            WHEN COALESCE(n.transit_stop_count_500m, 0) >= 1 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN d.nearest_transit_distance_m <= 200 THEN 3
            WHEN d.nearest_transit_distance_m <= 500 THEN 2
            WHEN d.nearest_transit_distance_m <= 800 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN COALESCE(n.parking_count_300m, 0) >= 3 THEN 2
            WHEN COALESCE(n.parking_count_300m, 0) >= 1 THEN 1
            ELSE 0
        END
    ) AS accessibility_score,

    /* Study score */
    (
        CASE WHEN c.serves_coffee THEN 1 ELSE 0 END
        + CASE WHEN c.serves_breakfast THEN 1 ELSE 0 END
        + CASE WHEN c.serves_brunch THEN 1 ELSE 0 END
        + CASE WHEN c.serves_lunch THEN 1 ELSE 0 END
        + CASE WHEN c.serves_dessert THEN 1 ELSE 0 END
        + CASE WHEN c.serves_vegetarian_food THEN 1 ELSE 0 END
    ) AS food_diversity_score,

    /* Competition score */
    (
        CASE
            WHEN COALESCE(n.competing_cafe_count_500m, 0) >= 10 THEN 3
            WHEN COALESCE(n.competing_cafe_count_500m, 0) >= 5 THEN 2
            WHEN COALESCE(n.competing_cafe_count_500m, 0) >= 1 THEN 1
            ELSE 0
        END
    ) AS competition_score,

    /* Demand score */
    (
        CASE
            WHEN c.rating >= 4.5 THEN 3
            WHEN c.rating >= 4.0 THEN 2
            WHEN c.rating >= 3.5 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN c.review_count >= 1000 THEN 3
            WHEN c.review_count >= 500 THEN 2
            WHEN c.review_count >= 100 THEN 1
            ELSE 0
        END
    ) AS demand_score,

    /* Opportunity score */
    (
        (
            CASE
                WHEN c.rating >= 4.5 THEN 3
                WHEN c.rating >= 4.0 THEN 2
                WHEN c.rating >= 3.5 THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN c.review_count >= 1000 THEN 3
                WHEN c.review_count >= 500 THEN 2
                WHEN c.review_count >= 100 THEN 1
                ELSE 0
            END
        )
        +
        (
            CASE 
                WHEN COALESCE(n.transit_stop_count_500m, 0) >= 5 THEN 3
                WHEN COALESCE(n.transit_stop_count_500m, 0) >= 2 THEN 2
                WHEN COALESCE(n.transit_stop_count_500m, 0) >= 1 THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN d.nearest_transit_distance_m <= 200 THEN 3
                WHEN d.nearest_transit_distance_m <= 500 THEN 2
                WHEN d.nearest_transit_distance_m <= 800 THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN COALESCE(n.parking_count_300m, 0) >= 3 THEN 2
                WHEN COALESCE(n.parking_count_300m, 0) >= 1 THEN 1
                ELSE 0
            END
        )
        +
        (
            CASE WHEN c.serves_coffee THEN 1 ELSE 0 END
            + CASE WHEN c.serves_breakfast THEN 1 ELSE 0 END
            + CASE WHEN c.serves_brunch THEN 1 ELSE 0 END
            + CASE WHEN c.serves_lunch THEN 1 ELSE 0 END
            + CASE WHEN c.serves_dessert THEN 1 ELSE 0 END
            + CASE WHEN c.serves_vegetarian_food THEN 1 ELSE 0 END
        )
        -
        (
            CASE
                WHEN COALESCE(n.competing_cafe_count_500m, 0) >= 10 THEN 3
                WHEN COALESCE(n.competing_cafe_count_500m, 0) >= 5 THEN 2
                WHEN COALESCE(n.competing_cafe_count_500m, 0) >= 1 THEN 1
                ELSE 0
            END
        )
    ) AS opportunity_score,

    CURRENT_TIMESTAMP() AS mart_created_at

FROM {{ ref('stg_unique_cafes') }} as c
LEFT JOIN {{ ref('int_cafe_nearby_features') }} as n
    ON c.cafe_id = n.cafe_id
LEFT JOIN {{ ref('int_cafe_distance_features') }} as d
    ON c.cafe_id = d.cafe_id