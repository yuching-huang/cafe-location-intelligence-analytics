from datetime import datetime

from airflow.sdk import dag, task

@dag(
    dag_id="test_cafe_pipeline",
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["cafe-intelligence"],
)
def test_cafe_pipeline():

    @task
    def start_pipeline():
        print("Cafe Location Intelligence pipeline started")

    @task
    def finish_pipeline():
        print("Cafe Location Intelligence pipeline completed")

    start_pipeline() >> finish_pipeline()

test_cafe_pipeline()