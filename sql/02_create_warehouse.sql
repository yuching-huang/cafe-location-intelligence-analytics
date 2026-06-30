-- create a warehouse for the cafe database
-- Type: Standard (Gen2)
-- Size: X-Small
-- Auto-resume: On
-- Auto-suspend: On
-- Suspend after: use 60 seconds if Snowflake accepts seconds/minutes depending on UI.
-- Multi-cluster: Off
-- Query acceleration: Off

CREATE OR REPLACE WAREHOUSE cafe_wh
WAREHOUSE_SIZE = XSMALL
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE
INITIALLY_SUSPENDED = TRUE;
