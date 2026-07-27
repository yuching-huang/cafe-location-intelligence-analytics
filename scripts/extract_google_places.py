# 1. Read neighborhoods.csv
# 2. Loop through each neighborhood
# 3. Call Google Places Text Search API
# 4. Generate a batch_id
# 5. Insert raw JSON results into Snowflake

import os
from pathlib import Path
import json
import uuid
import time
import requests
import pandas as pd
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


def get_snowflake_connection():
    """
    MFA with Push Notification (Duo Push)
    """
    
    print("Connecting with MFA push notification...")
    print("Please approve the push notification on your device.")

    return snowflake.connector.connect(
        user=SNOWFLAKE_USER,
        password=SNOWFLAKE_PASSWORD,
        account=SNOWFLAKE_ACCOUNT,
        warehouse=SNOWFLAKE_WAREHOUSE,
        database=SNOWFLAKE_DATABASE,
        schema=SNOWFLAKE_SCHEMA,
        role=SNOWFLAKE_ROLE,
    )


def search_cafes(search_query, max_results=20):
    url = "https://places.googleapis.com/v1/places:searchText"

    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_API_KEY,
        "X-Goog-FieldMask": (
            "places.id,"
            "places.displayName,"
            "places.formattedAddress,"
            "places.addressComponents,"
            "places.location,"
            "places.rating,"
            "places.userRatingCount,"
            "places.priceLevel,"
            "places.types,"
            "places.primaryType,"
            "places.regularOpeningHours,"
            "places.currentOpeningHours,"
            "places.parkingOptions,"
            "places.servesBreakfast,"
            "places.servesBrunch,"
            "places.servesLunch,"
            "places.servesDinner,"
            "places.servesDessert,"
            "places.servesCoffee,"
            "places.servesVegetarianFood"
        ),
    }

    payload = {
        "textQuery": search_query,
        "includedType": "cafe",
        "maxResultCount": max_results,
    }

    response = requests.post(url, headers=headers, json=payload)
    response.raise_for_status()

    return response.json().get("places", [])


def insert_raw_cafes(conn, batch_id, places, neighborhood):
    insert_sql = """
        INSERT INTO raw_google_places_cafes (
            batch_id,
            raw_data,
            search_neighborhood,
            source
        )
        SELECT
            %s,
            PARSE_JSON(%s),
            %s,
            %s
    """

    rows_inserted = 0

    with conn.cursor() as cur:
        for place in places:
            cur.execute(
                insert_sql,
                (
                    batch_id,
                    json.dumps(place),
                    neighborhood,
                    "google_places_text_search",
                ),
            )
            rows_inserted += 1

    return rows_inserted


def main():
    if not GOOGLE_API_KEY:
        raise ValueError("Missing GOOGLE_PLACES_API_KEY in .env")

    batch_id = str(uuid.uuid4())
    print(f"Starting batch: {batch_id}")

    ROOT = Path(__file__).resolve().parents[1]
    neighborhoods = pd.read_csv(ROOT / "data" / "neighborhoods.csv")

    conn = get_snowflake_connection()

    total_rows = 0

    try:
        for _, row in neighborhoods.iterrows():
            neighborhood = row["neighborhood"]
            search_query = row["search_query"]

            print(f"Searching cafes for: {neighborhood}")
            places = search_cafes(search_query, max_results=20)

            print(f"Found {len(places)} cafes for {neighborhood}")

            rows_inserted = insert_raw_cafes(
                conn=conn,
                batch_id=batch_id,
                places=places,
                neighborhood=neighborhood,
            )

            total_rows += rows_inserted

            # avoid hitting rate limits
            time.sleep(1)

        print(f"Finished batch: {batch_id}")
        print(f"Total rows inserted: {total_rows}")

    finally:
        conn.close()


if __name__ == "__main__":
    main()