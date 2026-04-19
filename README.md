# Hospital Performance Dashboard: ER Wait Time & Patient Flow (Power BI)

This dashboard analyzes ER wait time and patient flow to identify operational inefficiencies in emergency care delivery, with a focus on whether performance meets the 120-minute target. The report highlights inefficiencies in emergency care delivery.
<img width="1281" height="718" alt="dashboard" src="https://github.com/user-attachments/assets/6102f4d9-76bd-4a3e-9965-93af3ec0a62b" />

## Overview

This project is an end-to-end Power BI dashboard built to analyze:

* Emergency Room (ER) performance
* Patient flow and throughput
* Department-level cost and utilization

Key metrics included:

* ER wait time
* Total patient encounters
* Length of stay (LOS)
* Cost distribution by department

The dashboard focuses on identifying operational inefficiencies and monitoring whether performance meets expected service levels.

## Business Problem

Healthcare organizations often struggle with:

* ER wait times exceeding target service levels
* Inefficient patient flow across departments
* Limited visibility into key operational KPIs
* Difficulty identifying high-cost or high-volume areas

This project addresses key analytical questions:

* Are ER wait times meeting the 120-minute target?
* How does patient volume change over time?
* Which admission types drive the highest demand?
* Which departments contribute most to total cost?
* Where are potential bottlenecks in patient flow?

## Outcome

The analysis reveals that:

* ER wait time consistently exceeds the 120-minute target, indicating ongoing operational inefficiencies
* Patient volume remains relatively stable with periodic spikes, suggesting capacity pressure at certain periods
* Emergency admissions account for the largest share of encounters
* A small number of departments contribute disproportionately to total cost

The dashboard enables stakeholders to quickly identify performance gaps and monitor operational trends.

## Tech Stack
* Power BI – dashboard development and visualization
* DAX – KPI calculations and business logic
* Power Query – data transformation and shaping
* SQL (analytical view) – data preparation and modeling upstream

## Data Modeling Approach

Power BI connects to a curated SQL analytical view rather than raw transactional tables.

* Data cleaning, validation, and transformation were handled in SQL
* The SQL layer consolidates multiple sources into a single analytical dataset
* Power BI is used as a semantic and visualization layer, not for heavy data modeling

This approach explains why the model contains a single FactEncounter table instead of a traditional star schema — the dimensional modeling was performed upstream in SQL.

## Next Steps
* Add time-based comparisons (MoM / YoY trends)
* Introduce department-level wait time analysis
* Expand metrics (e.g., readmission rate, throughput efficiency)

## Author

Vladimir Sobur
Data Analyst | Power BI | SQL








