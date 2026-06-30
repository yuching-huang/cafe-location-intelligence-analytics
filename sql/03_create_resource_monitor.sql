-- Create a resource monitor for the cafe project
-- Name: cafe_project_monitor
-- Credit Quota: 5
-- Monitor Type: Warehouse
-- Schedule: Immediately / Never / Monthly

-- Actions:
-- 50%  → Notify
-- 80%  → Notify
-- 100% → Suspend immediately and notify


CREATE OR REPLACE RESOURCE MONITOR cafe_project_monitor
WITH CREDIT_QUOTA = 5
FREQUENCY = MONTHLY
START_TIMESTAMP = IMMEDIATELY
TRIGGERS
    ON 50 PERCENT DO NOTIFY
    ON 80 PERCENT DO NOTIFY
    ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE cafe_wh
SET RESOURCE_MONITOR = cafe_project_monitor;