
/*Project: Healthcare Portfolio Project
Platform: SQL Server
Purpose:
    Build a healthcare analytics dataset for Power BI using a practical, portfolio-ready workflow:
    1) create core dimension and fact tables
    2) load clean dimension files directly
    3) load raw encounter data into a staging table
    4) validate and transform staged data into the final fact table
    5) capture rejected rows for auditability
    6) create clean analytical views for reporting

Notes:
    - Dimension tables are loaded directly because they are relatively clean.
    - fact_encounter is loaded through a staging table because the raw file contains
      data quality issues such as extra spaces, inconsistent text, invalid dates,
      and negative cost values.
    - The final Power BI model should use the clean analytical views.
*/

USE HealthcarePortfolioProject;
GO

/*==============================================================
  PART 1. CORE TABLES
==============================================================*/

IF OBJECT_ID('dbo.fact_encounter', 'U') IS NOT NULL DROP TABLE dbo.fact_encounter;
IF OBJECT_ID('dbo.dim_diagnosis', 'U') IS NOT NULL DROP TABLE dbo.dim_diagnosis;
IF OBJECT_ID('dbo.dim_department', 'U') IS NOT NULL DROP TABLE dbo.dim_department;
IF OBJECT_ID('dbo.dim_patient', 'U') IS NOT NULL DROP TABLE dbo.dim_patient;


CREATE TABLE dbo.dim_patient (
    patient_id INT NOT NULL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    gender VARCHAR(20) NULL,
    date_of_birth DATE NULL,
    age INT NULL,
    city VARCHAR(100) NULL,
    state VARCHAR(50) NULL,
    insurance_type VARCHAR(50) NULL
);
GO

CREATE TABLE dbo.dim_department (
    department_id INT NOT NULL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    service_line VARCHAR(100) NULL
);
GO

CREATE TABLE dbo.dim_diagnosis (
    diagnosis_id INT NOT NULL PRIMARY KEY,
    diagnosis_name VARCHAR(150) NOT NULL,
    diagnosis_group VARCHAR(100) NULL
);
GO

CREATE TABLE dbo.fact_encounter (
    encounter_id INT NOT NULL PRIMARY KEY,
    patient_id INT NOT NULL,
    department_id INT NOT NULL,
    diagnosis_id INT NOT NULL,
    admission_date DATETIME NOT NULL,
    discharge_date DATETIME NULL,
    er_arrival_time DATETIME NULL,
    provider_seen_time DATETIME NULL,
    encounter_type VARCHAR(50) NOT NULL,
    admission_type VARCHAR(50) NULL,
    discharge_disposition VARCHAR(50) NULL,
    total_cost DECIMAL(12,2) NULL,
    bed_days INT NULL,
    CONSTRAINT fk_fact_encounter_patient
        FOREIGN KEY (patient_id) REFERENCES dbo.dim_patient(patient_id),
    CONSTRAINT fk_fact_encounter_department
        FOREIGN KEY (department_id) REFERENCES dbo.dim_department(department_id),
    CONSTRAINT fk_fact_encounter_diagnosis
        FOREIGN KEY (diagnosis_id) REFERENCES dbo.dim_diagnosis(diagnosis_id)
);
GO

/* Optional validation */
SELECT *
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('dim_patient', 'dim_department', 'dim_diagnosis', 'fact_encounter');
GO

/*==============================================================
  PART 2. LOAD CLEAN DIMENSION TABLES
  Update file paths as needed before running.
==============================================================*/
TRUNCATE TABLE dbo.fact_encounter;

DELETE FROM dbo.dim_patient;
DELETE FROM dbo.dim_department;
DELETE FROM dbo.dim_diagnosis;

BULK INSERT dbo.dim_patient
FROM 'C:\Temporary_folder\Portfolio_Project_data\dim_patient.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

BULK INSERT dbo.dim_department
FROM 'C:\Temporary_folder\Portfolio_Project_data\dim_department.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

BULK INSERT dbo.dim_diagnosis
FROM 'C:\Temporary_folder\Portfolio_Project_data\dim_diagnosis.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


SELECT COUNT(*) AS dim_patient_row_count FROM dbo.dim_patient;
SELECT COUNT(*) AS dim_department_row_count FROM dbo.dim_department;
SELECT COUNT(*) AS dim_diagnosis_row_count FROM dbo.dim_diagnosis;
GO

/*==============================================================
  PART 3. LOAD RAW FACT DATA INTO STAGING
==============================================================*/
IF OBJECT_ID('dbo.fact_encounter_stg', 'U') IS NOT NULL
    DROP TABLE dbo.fact_encounter_stg;
GO

CREATE TABLE dbo.fact_encounter_stg (
    encounter_id VARCHAR(100) NULL,
    patient_id VARCHAR(100) NULL,
    department_id VARCHAR(100) NULL,
    diagnosis_id VARCHAR(100) NULL,
    admission_date VARCHAR(100) NULL,
    discharge_date VARCHAR(100) NULL,
    er_arrival_time VARCHAR(100) NULL,
    provider_seen_time VARCHAR(100) NULL,
    encounter_type VARCHAR(100) NULL,
    admission_type VARCHAR(100) NULL,
    discharge_disposition VARCHAR(100) NULL,
    total_cost VARCHAR(100) NULL,
    bed_days VARCHAR(100) NULL
);
GO

BULK INSERT dbo.fact_encounter_stg
FROM 'C:\Temporary_folder\Portfolio_Project_data\fact_encounter.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

/* After loading data, validate the staging row count. */
SELECT COUNT(*) AS fact_encounter_stg_row_count
FROM dbo.fact_encounter_stg;
GO

/*==============================================================
  PART 4. TRANSFORM AND LOAD THE CURATED FACT TABLE
==============================================================*/

TRUNCATE TABLE dbo.fact_encounter;
GO

INSERT INTO dbo.fact_encounter (
    encounter_id,
    patient_id,
    department_id,
    diagnosis_id,
    admission_date,
    discharge_date,
    er_arrival_time,
    provider_seen_time,
    encounter_type,
    admission_type,
    discharge_disposition,
    total_cost,
    bed_days
)
SELECT
    TRY_CAST(LTRIM(RTRIM(encounter_id)) AS INT) AS encounter_id,
    TRY_CAST(LTRIM(RTRIM(patient_id)) AS INT) AS patient_id,
    TRY_CAST(LTRIM(RTRIM(department_id)) AS INT) AS department_id,
    TRY_CAST(LTRIM(RTRIM(diagnosis_id)) AS INT) AS diagnosis_id,
    TRY_CAST(LTRIM(RTRIM(admission_date)) AS DATETIME) AS admission_date,
    TRY_CAST(NULLIF(LTRIM(RTRIM(discharge_date)), '') AS DATETIME) AS discharge_date,
    TRY_CAST(NULLIF(LTRIM(RTRIM(er_arrival_time)), '') AS DATETIME) AS er_arrival_time,
    TRY_CAST(NULLIF(LTRIM(RTRIM(provider_seen_time)), '') AS DATETIME) AS provider_seen_time,
    NULLIF(LTRIM(RTRIM(encounter_type)), '') AS encounter_type,
    NULLIF(LTRIM(RTRIM(admission_type)), '') AS admission_type,
    NULLIF(LTRIM(RTRIM(discharge_disposition)), '') AS discharge_disposition,
    TRY_CAST(NULLIF(LTRIM(RTRIM(total_cost)), '') AS DECIMAL(12,2)) AS total_cost,
    TRY_CAST(NULLIF(LTRIM(RTRIM(bed_days)), '') AS INT) AS bed_days
FROM dbo.fact_encounter_stg
WHERE
    TRY_CAST(LTRIM(RTRIM(encounter_id)) AS INT) IS NOT NULL
    AND TRY_CAST(LTRIM(RTRIM(patient_id)) AS INT) IS NOT NULL
    AND TRY_CAST(LTRIM(RTRIM(department_id)) AS INT) IS NOT NULL
    AND TRY_CAST(LTRIM(RTRIM(diagnosis_id)) AS INT) IS NOT NULL
    AND TRY_CAST(LTRIM(RTRIM(admission_date)) AS DATETIME) IS NOT NULL
    AND TRY_CAST(LTRIM(RTRIM(patient_id)) AS INT) IN (SELECT patient_id FROM dbo.dim_patient)
    AND TRY_CAST(LTRIM(RTRIM(department_id)) AS INT) IN (SELECT department_id FROM dbo.dim_department)
    AND TRY_CAST(LTRIM(RTRIM(diagnosis_id)) AS INT) IN (SELECT diagnosis_id FROM dbo.dim_diagnosis)
    AND (
        TRY_CAST(NULLIF(LTRIM(RTRIM(discharge_date)), '') AS DATETIME) IS NULL
        OR TRY_CAST(NULLIF(LTRIM(RTRIM(discharge_date)), '') AS DATETIME)
           >= TRY_CAST(LTRIM(RTRIM(admission_date)) AS DATETIME)
    )
    AND (
        TRY_CAST(NULLIF(LTRIM(RTRIM(total_cost)), '') AS DECIMAL(12,2)) IS NULL
        OR TRY_CAST(NULLIF(LTRIM(RTRIM(total_cost)), '') AS DECIMAL(12,2)) >= 0
    );
GO

SELECT COUNT(*) AS fact_encounter_row_count
FROM dbo.fact_encounter;
GO

/*==============================================================
  PART 5. DATA QUALITY CHECKS AND REJECT TABLE
==============================================================*/

WITH validation_summary AS (
    SELECT
        SUM(CASE WHEN TRY_CAST(LTRIM(RTRIM(encounter_id)) AS INT) IS NULL THEN 1 ELSE 0 END) AS bad_encounter_id,
        SUM(CASE WHEN TRY_CAST(LTRIM(RTRIM(patient_id)) AS INT) IS NULL THEN 1 ELSE 0 END) AS bad_patient_id,
        SUM(CASE WHEN TRY_CAST(LTRIM(RTRIM(department_id)) AS INT) IS NULL THEN 1 ELSE 0 END) AS bad_department_id,
        SUM(CASE WHEN TRY_CAST(LTRIM(RTRIM(diagnosis_id)) AS INT) IS NULL THEN 1 ELSE 0 END) AS bad_diagnosis_id,
        SUM(CASE WHEN TRY_CAST(LTRIM(RTRIM(admission_date)) AS DATETIME) IS NULL THEN 1 ELSE 0 END) AS bad_admission_date,
        SUM(CASE
                WHEN TRY_CAST(NULLIF(LTRIM(RTRIM(discharge_date)), '') AS DATETIME) IS NOT NULL
                 AND TRY_CAST(NULLIF(LTRIM(RTRIM(discharge_date)), '') AS DATETIME)
                     < TRY_CAST(LTRIM(RTRIM(admission_date)) AS DATETIME)
                THEN 1 ELSE 0
            END) AS bad_discharge_before_admission,
        SUM(CASE
                WHEN TRY_CAST(NULLIF(LTRIM(RTRIM(total_cost)), '') AS DECIMAL(12,2)) IS NOT NULL
                 AND TRY_CAST(NULLIF(LTRIM(RTRIM(total_cost)), '') AS DECIMAL(12,2)) < 0
                THEN 1 ELSE 0
            END) AS negative_total_cost
    FROM dbo.fact_encounter_stg
)
SELECT *
FROM validation_summary;
GO

SELECT TOP 50 *
FROM dbo.fact_encounter_stg
WHERE
    TRY_CAST(LTRIM(RTRIM(encounter_id)) AS INT) IS NULL
    OR TRY_CAST(LTRIM(RTRIM(patient_id)) AS INT) IS NULL
    OR TRY_CAST(LTRIM(RTRIM(department_id)) AS INT) IS NULL
    OR TRY_CAST(LTRIM(RTRIM(diagnosis_id)) AS INT) IS NULL
    OR TRY_CAST(LTRIM(RTRIM(admission_date)) AS DATETIME) IS NULL
    OR (
        TRY_CAST(NULLIF(LTRIM(RTRIM(discharge_date)), '') AS DATETIME) IS NOT NULL
        AND TRY_CAST(NULLIF(LTRIM(RTRIM(discharge_date)), '') AS DATETIME)
            < TRY_CAST(LTRIM(RTRIM(admission_date)) AS DATETIME)
    )
    OR (
        TRY_CAST(NULLIF(LTRIM(RTRIM(total_cost)), '') AS DECIMAL(12,2)) IS NOT NULL
        AND TRY_CAST(NULLIF(LTRIM(RTRIM(total_cost)), '') AS DECIMAL(12,2)) < 0
    );
GO

IF OBJECT_ID('dbo.fact_encounter_rejects', 'U') IS NOT NULL
    DROP TABLE dbo.fact_encounter_rejects;
GO

SELECT *
INTO dbo.fact_encounter_rejects
FROM dbo.fact_encounter_stg
WHERE
    TRY_CAST(LTRIM(RTRIM(encounter_id)) AS INT) IS NULL
    OR TRY_CAST(LTRIM(RTRIM(patient_id)) AS INT) IS NULL
    OR TRY_CAST(LTRIM(RTRIM(department_id)) AS INT) IS NULL
    OR TRY_CAST(LTRIM(RTRIM(diagnosis_id)) AS INT) IS NULL
    OR TRY_CAST(LTRIM(RTRIM(admission_date)) AS DATETIME) IS NULL
    OR (
        TRY_CAST(NULLIF(LTRIM(RTRIM(discharge_date)), '') AS DATETIME) IS NOT NULL
        AND TRY_CAST(NULLIF(LTRIM(RTRIM(discharge_date)), '') AS DATETIME)
            < TRY_CAST(LTRIM(RTRIM(admission_date)) AS DATETIME)
    )
    OR (
        TRY_CAST(NULLIF(LTRIM(RTRIM(total_cost)), '') AS DECIMAL(12,2)) IS NOT NULL
        AND TRY_CAST(NULLIF(LTRIM(RTRIM(total_cost)), '') AS DECIMAL(12,2)) < 0
    );
GO

SELECT COUNT(*) AS reject_count
FROM dbo.fact_encounter_rejects;
GO

SELECT
    COUNT(*) AS total_rows,
    (SELECT COUNT(*) FROM dbo.fact_encounter) AS valid_rows,
    (SELECT COUNT(*) FROM dbo.fact_encounter_rejects) AS rejected_rows
FROM dbo.fact_encounter_stg;
GO

SELECT TOP 5 *
FROM dbo.fact_encounter_rejects;
GO

/*
Expected result for this generated dataset:
- total staged rows: 10000
- rejected rows: 145
- valid rows loaded to fact_encounter: 9855
*/

/*==============================================================
  PART 6. CLEAN ANALYTICAL VIEWS FOR POWER BI
==============================================================*/

IF OBJECT_ID('dbo.vw_kpi_readmission', 'V') IS NOT NULL DROP VIEW dbo.vw_kpi_readmission;
IF OBJECT_ID('dbo.vw_kpi_los_by_department', 'V') IS NOT NULL DROP VIEW dbo.vw_kpi_los_by_department;
IF OBJECT_ID('dbo.vw_fact_encounter_clean', 'V') IS NOT NULL DROP VIEW dbo.vw_fact_encounter_clean;
IF OBJECT_ID('dbo.vw_dim_diagnosis_clean', 'V') IS NOT NULL DROP VIEW dbo.vw_dim_diagnosis_clean;
IF OBJECT_ID('dbo.vw_dim_department_clean', 'V') IS NOT NULL DROP VIEW dbo.vw_dim_department_clean;
IF OBJECT_ID('dbo.vw_dim_patient_clean', 'V') IS NOT NULL DROP VIEW dbo.vw_dim_patient_clean;
GO

CREATE VIEW dbo.vw_dim_patient_clean AS
SELECT
    patient_id,
    LTRIM(RTRIM(first_name)) AS first_name,
    LTRIM(RTRIM(last_name)) AS last_name,
    UPPER(LTRIM(RTRIM(gender))) AS gender,
    date_of_birth,
    age,
    LTRIM(RTRIM(city)) AS city,
    UPPER(LTRIM(RTRIM(state))) AS state,
    UPPER(LTRIM(RTRIM(insurance_type))) AS insurance_type
FROM dbo.dim_patient;
GO

CREATE VIEW dbo.vw_dim_department_clean AS
SELECT
    department_id,
    LTRIM(RTRIM(department_name)) AS department_name,
    LTRIM(RTRIM(service_line)) AS service_line
FROM dbo.dim_department;
GO

CREATE VIEW dbo.vw_dim_diagnosis_clean AS
SELECT
    diagnosis_id,
    LTRIM(RTRIM(diagnosis_name)) AS diagnosis_name,
    LTRIM(RTRIM(diagnosis_group)) AS diagnosis_group
FROM dbo.dim_diagnosis;
GO

CREATE VIEW dbo.vw_fact_encounter_clean AS
SELECT
    f.encounter_id,
    f.patient_id,
    p.first_name,
    p.last_name,
    p.gender,
    p.age,
    p.city,
    p.state,
    p.insurance_type,

    f.department_id,
    d.department_name,
    d.service_line,

    f.diagnosis_id,
    dx.diagnosis_name,
    dx.diagnosis_group,

    CAST(f.admission_date AS DATE) AS admission_date,
    CAST(f.discharge_date AS DATE) AS discharge_date,
    f.er_arrival_time,
    f.provider_seen_time,

    UPPER(LTRIM(RTRIM(f.encounter_type))) AS encounter_type,
    UPPER(LTRIM(RTRIM(f.admission_type))) AS admission_type,
    UPPER(LTRIM(RTRIM(f.discharge_disposition))) AS discharge_disposition,

    f.total_cost,
    f.bed_days,

    CASE
        WHEN f.discharge_date IS NOT NULL
        THEN DATEDIFF(DAY, f.admission_date, f.discharge_date)
        ELSE NULL
    END AS length_of_stay,

    CASE
        WHEN f.er_arrival_time IS NOT NULL
         AND f.provider_seen_time IS NOT NULL
        THEN DATEDIFF(MINUTE, f.er_arrival_time, f.provider_seen_time)
        ELSE NULL
    END AS er_wait_time_minutes,

    FORMAT(f.admission_date, 'yyyy-MM') AS admission_month
FROM dbo.fact_encounter f
LEFT JOIN dbo.vw_dim_patient_clean p
    ON f.patient_id = p.patient_id
LEFT JOIN dbo.vw_dim_department_clean d
    ON f.department_id = d.department_id
LEFT JOIN dbo.vw_dim_diagnosis_clean dx
    ON f.diagnosis_id = dx.diagnosis_id;
GO

CREATE VIEW dbo.vw_kpi_los_by_department AS
SELECT
    department_name,
    AVG(length_of_stay * 1.0) AS avg_los
FROM dbo.vw_fact_encounter_clean
WHERE length_of_stay IS NOT NULL
GROUP BY department_name;
GO

CREATE VIEW dbo.vw_kpi_readmission AS
WITH patient_visits AS (
    SELECT
        patient_id,
        admission_date,
        discharge_date,
        LAG(discharge_date) OVER (
            PARTITION BY patient_id
            ORDER BY admission_date
        ) AS prev_discharge
    FROM dbo.vw_fact_encounter_clean
)
SELECT
    COUNT(*) AS total_visits,
    SUM(CASE
            WHEN prev_discharge IS NOT NULL
             AND DATEDIFF(DAY, prev_discharge, admission_date) BETWEEN 0 AND 30
            THEN 1 ELSE 0
        END) AS readmissions,
    CAST(
        SUM(CASE
                WHEN prev_discharge IS NOT NULL
                 AND DATEDIFF(DAY, prev_discharge, admission_date) BETWEEN 0 AND 30
                THEN 1 ELSE 0
            END) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS readmission_rate
FROM patient_visits;
GO

/*==============================================================
  PART 7. FINAL CHECKS
==============================================================*/

SELECT TOP 20 *
FROM dbo.vw_fact_encounter_clean;


SELECT *
FROM dbo.vw_kpi_los_by_department
ORDER BY avg_los DESC;


SELECT *
FROM dbo.vw_kpi_readmission;
