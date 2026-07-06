import os
import json
import uuid
import time
import requests
import snowflake.connector
from dotenv import load_dotenv

load_dotenv()

GOOGLE_API_KEY = os.getenv("GOOGLE_PLACES_API_KEY")

SNOWFLAKE_USER = os.getenv("SNOWFLAKE_USER")
SNOWFLAKE_PASSWORD = os.getenv("SNOWFLAKE_PASSWORD")
SNOWFLAKE_ACCOUNT = os.getenv("SNOWFLAKE_ACCOUNT")
SNOWFLAKE_WAREHOUSE = os.getenv("SNOWFLAKE_WAREHOUSE")
SNOWFLAKE_DATABASE = os.getenv("SNOWFLAKE_DATABASE")
SNOWFLAKE_SCHEMA = os.getenv("SNOWFLAKE_SCHEMA")
SNOWFLAKE_ROLE = os.getenv("SNOWFLAKE_ROLE")


AMENITY_SEARCH_CONFIG = [
    {
        "amenity_type": "transit_station",
        "included_types": ["transit_station"],
        "radius_meters": 500,
    },
    {
        "amenity_type": "parking",
        "included_types": ["parking"],
        "radius_meters": 300,
    },
    {
        "amenity_type": "competing_cafe",
        "included_types": ["cafe"],
        "radius_meters": 500,
    },
]


def get_snowflake_connection():
    return snowflake.connector.connect(
        user=SNOWFLAKE_USER,
        password=SNOWFLAKE_PASSWORD,
        account=SNOWFLAKE_ACCOUNT,
        warehouse=SNOWFLAKE_WAREHOUSE,
        database=SNOWFLAKE_DATABASE,
        schema=SNOWFLAKE_SCHEMA,
        role=SNOWFLAKE_ROLE,
    )


def get_cafes_to_enrich(conn, limit=160):
    # pull cafes that have not yet been enriched with nearby places data
    query = """
        SELECT
            c.cafe_id,
            c.cafe_name,
            c.latitude,
            c.longitude
        FROM cafe_location_intelligence.staging.stg_google_places_cafes c
        WHERE c.latitude IS NOT NULL
          AND c.longitude IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM cafe_location_intelligence.raw.raw_google_nearby_places n
              WHERE n.cafe_place_id = c.cafe_id
          )
        LIMIT %s
    """

    with conn.cursor() as cur:
        cur.execute(query, (limit,))
        rows = cur.fetchall()

    cafes = []
    for row in rows:
        cafes.append({
            "cafe_id": row[0],
            "cafe_name": row[1],
            "latitude": float(row[2]),
            "longitude": float(row[3]),
        })

    return cafes


def search_nearby_places(latitude, longitude, included_types, radius_meters, max_results=10):
    url = "https://places.googleapis.com/v1/places:searchNearby"

    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_API_KEY,
        "X-Goog-FieldMask": (
            "places.id,"
            "places.displayName,"
            "places.types,"
            "places.primaryType,"
            "places.location,"
            "places.rating,"
            "places.userRatingCount,"
            "places.formattedAddress"
        ),
    }

    payload = {
        "includedTypes": included_types,
        "maxResultCount": max_results,
        "locationRestriction": {
            "circle": {
                "center": {
                    "latitude": latitude,
                    "longitude": longitude,
                },
                "radius": radius_meters,
            }
        },
    }

    response = requests.post(url, headers=headers, json=payload)
    response.raise_for_status()

    return response.json().get("places", [])


def insert_raw_nearby_places(
    conn,
    batch_id,
    cafe_place_id,
    amenity_type,
    radius_meters,
    places,
):
    insert_sql = """
        INSERT INTO raw_google_nearby_places (
            batch_id,
            cafe_place_id,
            amenity_type,
            search_radius_meters,
            raw_data,
            source
        )
        SELECT
            %s,
            %s,
            %s,
            %s,
            PARSE_JSON(%s),
            %s
    """

    rows_inserted = 0

    with conn.cursor() as cur:
        for place in places:
            cur.execute(
                insert_sql,
                (
                    batch_id,
                    cafe_place_id,
                    amenity_type,
                    radius_meters,
                    json.dumps(place),
                    "google_places_nearby_search",
                ),
            )
            rows_inserted += 1

    return rows_inserted


def main():
    if not GOOGLE_API_KEY:
        raise ValueError("Missing GOOGLE_PLACES_API_KEY in .env")

    batch_id = str(uuid.uuid4())
    print(f"Starting nearby enrichment batch: {batch_id}")

    conn = get_snowflake_connection()

    total_rows = 0

    try:
        cafes = get_cafes_to_enrich(conn, limit=160)
        print(f"Found {len(cafes)} cafes to enrich")

        for cafe in cafes:
            print(f"Enriching: {cafe['cafe_name']}")

            for config in AMENITY_SEARCH_CONFIG:
                amenity_type = config["amenity_type"]
                included_types = config["included_types"]
                radius_meters = config["radius_meters"]

                print(f"  Searching nearby: {amenity_type}")

                nearby_places = search_nearby_places(
                    latitude=cafe["latitude"],
                    longitude=cafe["longitude"],
                    included_types=included_types,
                    radius_meters=radius_meters,
                    max_results=10,
                )

                rows_inserted = insert_raw_nearby_places(
                    conn=conn,
                    batch_id=batch_id,
                    cafe_place_id=cafe["cafe_id"],
                    amenity_type=amenity_type,
                    radius_meters=radius_meters,
                    places=nearby_places,
                )

                print(f"  Inserted {rows_inserted} {amenity_type} rows")
                total_rows += rows_inserted

                time.sleep(0.5)

            if total_rows == 0:
                print(f"{cafe['cafe_name']} - No nearby {amenity_type} found. Skipping further enrichment.")
                continue

        print(f"Finished nearby enrichment batch: {batch_id}")
        print(f"Total nearby rows inserted: {total_rows}")

    finally:
        conn.close()


if __name__ == "__main__":
    main()