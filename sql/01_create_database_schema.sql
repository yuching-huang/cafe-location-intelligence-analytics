USE WAREHOUSE cafe_wh;

CREATE OR REPLACE DATABASE cafe_location_intelligence;

-- store original API data from Google Places
CREATE OR REPLACE SCHEMA cafe_location_intelligence.raw;

-- clean/standardized data
CREATE OR REPLACE SCHEMA cafe_location_intelligence.staging;

-- final analytics ready table
CREATE OR REPLACE SCHEMA cafe_location_intelligence.marts;