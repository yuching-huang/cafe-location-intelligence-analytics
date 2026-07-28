# Los Angeles Cafe Location Intelligence Analytics

An end-to-end cloud data engineering project that automates the collection, transformation, and analysis of cafe location intelligence across Los Angeles neighborhoods. The pipeline integrates data from the Google Places API, orchestrates workflows with Apache Airflow, transforms data in Snowflake using dbt, and produces analytics-ready datasets for business intelligence dashboards.

---

## Overview

As flexible work and study habits reshape how people use urban spaces, cafes have become important destinations for students, remote workers, and professionals seeking productive work environments. However, not every neighborhood offers the same level of accessibility, competition, or business opportunity.

This project builds an automated analytics pipeline to evaluate cafes and neighborhoods using location, accessibility, customer engagement, and competitive landscape data to support data-driven site selection and market analysis.

This project is designed to answer five key business questions:

- Which cafes offer the best environment for studying, working, or spending extended periods of time?
- Which neighborhoods exhibit high demand but low café saturation?
- Does accessibility (public transit and parking) influence customer engagement?
- Which cafes are "hidden gems" with high ratings but relatively low visibility?
- Which neighborhoods present the strongest opportunities for future café investment?

---

## Architecture

```text
            Google Places API
                     │
                     ▼
        Python Extraction Scripts
                     │
                     ▼
       Apache Airflow Orchestration
                     │
                     ▼
        Snowflake Raw JSON Tables
                     │
                     ▼
            dbt Staging Models
                     │
                     ▼
        dbt Intermediate Feature Models
                     │
                     ▼
            dbt Analytics Mart
                     │
                     ▼
            Tableau Dashboard
```

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| Programming | Python, SQL |
| Workflow Orchestration | Apache Airflow |
| Data Warehouse | Snowflake |
| Data Transformation | dbt |
| Data Sources | Google Places API |
| Visualization | Tableau |
| Version Control | Git & GitHub |

---

## Data Pipeline

### 1. Data Extraction

Python scripts retrieve café information from the Google Places API, including:

- Name
- Address
- Geographic coordinates
- Rating
- Review count
- Price range
- Categories
- Opening hours
- Business attributes

Additional nearby location information is collected to measure accessibility and competition.

---

### 2. Workflow Orchestration

Apache Airflow automates the end-to-end workflow:

```text
        Extract Cafe Data
                │
                ▼
      Extract Nearby Places
                │
                ▼
    Load Raw Data into Snowflake
                │
                ▼
          Run dbt Models
                │
                ▼
     Data Quality Validation
```

The DAG is currently set to manual trigger (`schedule=None`) during development; a cron expression can be added to `cafe_location_pipeline.py` to automate refreshes once the project moves past testing.

---

### 3. Data Warehouse Design

The project follows a layered data warehouse architecture.

| Layer | Purpose |
|--------|---------|
| Raw | Store original API responses with minimal modification |
| Staging | Parse JSON, standardize schema, cast data types, deduplicate records |
| Intermediate | Create reusable business logic and geospatial features |
| Mart | Produce dashboard-ready analytical datasets |

Example tables include:

```text
RAW
├── raw_google_places_cafes
├── raw_google_nearby_places
└── manual_cafe_enrichment

STAGING
├── stg_google_places_cafes
├── stg_unique_cafes
└── stg_google_nearby_cafes

INTERMEDIATE
├── int_cafe_distance_features
└── int_cafe_nearby_features

MART
└── mart_cafe_location
```

---

## Data Quality & Testing

Every dbt model is covered by column-level tests defined in schema YAML files, including:

- `not_null` and `unique` constraints on primary keys
- `relationships` tests to enforce referential integrity between staging, intermediate, and mart layers
- `accepted_values` checks (e.g., `amenity_type` must be one of `transit_station`, `parking`, `competing_cafe`)
- `dbt_utils.accepted_range` checks on ratings, coordinates, counts, and composite scores

This catches malformed API responses, broken joins, and out-of-range scores before they reach the analytics mart.

---

## Key Business Metrics

| Category | Metrics |
|----------|---------|
| Cafe Performance | Rating, review count, price range, categories |
| Accessibility | Transit stop count and distance (500m), parking availability and distance (300m) |
| Food & Study Diversity | Breakfast, brunch, lunch, dinner, dessert, and vegetarian options served |
| Competition | Nearby competing café count, average competitor rating, competitor review volume |
| Opportunity Score | Composite score: demand + accessibility + food diversity − competition |

Seating capacity and parking notes are captured manually in a `manual_cafe_enrichment` raw table for future incorporation into the scoring model (see Future Enhancements).

---

## Data Refresh Strategy

To balance data freshness and API cost:

- Perform a full extraction across all target neighborhoods during the initial build.
- Refresh data every two months for the portfolio project.
- Optionally perform monthly updates for frequently changing attributes such as ratings, review counts, and operating hours.
- Use `place_id` as the primary identifier to support incremental updates and prevent duplicate records.
- Use Google Places field masks to minimize unnecessary API costs.

---

## Example Analytical Use Cases

The final analytics mart enables analysis such as:

- Ranking neighborhoods by café opportunity
- Identifying underserved markets
- Measuring the relationship between accessibility and customer engagement
- Discovering highly rated cafes with limited visibility
- Comparing competitive intensity across neighborhoods

---

## Skills Demonstrated

- Data Engineering
- ELT Pipeline Development
- API Integration
- Workflow Orchestration
- Cloud Data Warehousing
- Data Modeling
- SQL
- Python
- Apache Airflow
- dbt
- Snowflake
- Tableau
- Git

---

## Future Enhancements

Future iterations of the project may include:

- Incorporating `manual_cafe_enrichment` data (seating capacity, parking notes) into the opportunity score
- Incremental dbt models
- Snowflake Streams & Tasks
- Demographic enrichment using Census data
- Weather and seasonal demand analysis
- Automated CI/CD deployment
- Docker containerization
- Deployment to a managed Airflow environment (Amazon MWAA or Google Cloud Composer)