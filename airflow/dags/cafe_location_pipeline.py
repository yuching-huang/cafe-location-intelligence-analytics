from datetime import datetime
from pathlib import Path

from airflow import DAG
from airflow.operators.bash import BashOperator


# Project root:
# cafe-location-intelligence-analytics/
PROJECT_ROOT = Path(__file__).resolve().parents[2]

PYTHON_PATH = Path("/Users/jennifer/anaconda3/envs/cafe-intel/bin/python")
DBT_PROJECT_PATH = PROJECT_ROOT / "dbt" / "cafe_intelligence"

with DAG(
    dag_id="cafe_location_pipeline",
    description="Extract cafe data, extract nearby places, and run dbt models",
    start_date=datetime(2026, 1, 1),
    schedule=None,  # Manual trigger while testing
    catchup=False,
    tags=["cafe", "google-places", "dbt"],
) as dag:

    extract_google_places = BashOperator(
        task_id="extract_google_places",
        bash_command=(
            f'cd "{PROJECT_ROOT}" && '
            f'"{PYTHON_PATH}" scripts/extract_google_places.py'
        ),
    )

    extract_nearby_places = BashOperator(
        task_id="extract_nearby_places",
        bash_command=(
            f'cd "{PROJECT_ROOT}" && '
            f'"{PYTHON_PATH}" scripts/extract_nearby_places.py'
        ),
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=(
            f'cd "{DBT_PROJECT_PATH}" && '
            "dbt build"
        ),
    )

    extract_google_places >> extract_nearby_places >> dbt_build