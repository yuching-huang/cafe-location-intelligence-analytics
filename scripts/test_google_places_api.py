import os
import json
import requests
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("GOOGLE_PLACES_API_KEY")

if not API_KEY:
    raise ValueError("Missing GOOGLE_PLACES_API_KEY in .env file")

url = "https://places.googleapis.com/v1/places:searchText"

headers = {
    "Content-Type": "application/json",
    "X-Goog-Api-Key": API_KEY,
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
        "places.regularOpeningHours"
    )
}

payload = {
    "textQuery": "cafes in Koreatown Los Angeles CA",
    "includedType": "cafe",
    "maxResultCount": 2
}

response = requests.post(url, headers=headers, json=payload)
response.raise_for_status()

data = response.json()

print(json.dumps(data, indent=2))