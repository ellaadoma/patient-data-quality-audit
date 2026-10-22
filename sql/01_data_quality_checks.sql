-- Healthcare Patient Data Quality Audit
-- Check 1: Total records vs. unique patient IDs

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT Id) AS unique_patient_ids,
    COUNT(*) - COUNT(DISTINCT Id) AS potential_duplicate_ids
FROM patients;

-- Check 2: Counting missing values in key demographic fields

SELECT
    SUM(CASE WHEN BIRTHDATE IS NULL OR TRIM(BIRTHDATE) = '' THEN 1 ELSE 0 END) AS missing_birthdate,
    SUM(CASE WHEN GENDER IS NULL OR TRIM(GENDER) = '' THEN 1 ELSE 0 END) AS missing_gender,
    SUM(CASE WHEN RACE IS NULL OR TRIM(RACE) = '' THEN 1 ELSE 0 END) AS missing_race,
    SUM(CASE WHEN ETHNICITY IS NULL OR TRIM(ETHNICITY) = '' THEN 1 ELSE 0 END) AS missing_ethnicity,
    SUM(CASE WHEN CITY IS NULL OR TRIM(CITY) = '' THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN STATE IS NULL OR TRIM(STATE) = '' THEN 1 ELSE 0 END) AS missing_state
FROM patients;

-- Check 3: Identifying invalid or inconsistent patient dates

SELECT
    SUM(
        CASE
            WHEN date(BIRTHDATE) IS NULL THEN 1
            WHEN date(BIRTHDATE) > date('now') THEN 1
            ELSE 0
        END
    ) AS invalid_or_future_birthdates,

    SUM(
        CASE
            WHEN DEATHDATE IS NOT NULL
                 AND TRIM(DEATHDATE) <> ''
                 AND date(DEATHDATE) IS NULL
            THEN 1
            ELSE 0
        END
    ) AS invalid_deathdate_formats,

    SUM(
        CASE
            WHEN DEATHDATE IS NOT NULL
                 AND TRIM(DEATHDATE) <> ''
                 AND date(DEATHDATE) < date(BIRTHDATE)
            THEN 1
            ELSE 0
        END
    ) AS death_before_birth

FROM patients;

-- Check 4: Inspect distinct demographic category values

SELECT
    'GENDER' AS field_name,
    GENDER AS field_value,
    COUNT(*) AS record_count
FROM patients
GROUP BY GENDER

UNION ALL

SELECT
    'MARITAL' AS field_name,
    MARITAL AS field_value,
    COUNT(*) AS record_count
FROM patients
GROUP BY MARITAL

ORDER BY field_name, field_value;

-- Check 5: Measure missing marital status

SELECT
    COUNT(*) AS total_records,
    SUM(
        CASE
            WHEN MARITAL IS NULL OR TRIM(MARITAL) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_marital_status,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN MARITAL IS NULL OR TRIM(MARITAL) = ''
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS missing_marital_status_pct
FROM patients;

-- Check 6: Missing values in names and identifier fields
-- Do not display the actual identifier values.

SELECT
    SUM(CASE WHEN PREFIX IS NULL OR TRIM(PREFIX) = '' THEN 1 ELSE 0 END) AS missing_prefix,
    SUM(CASE WHEN FIRST IS NULL OR TRIM(FIRST) = '' THEN 1 ELSE 0 END) AS missing_first_name,
    SUM(CASE WHEN MIDDLE IS NULL OR TRIM(MIDDLE) = '' THEN 1 ELSE 0 END) AS missing_middle_name,
    SUM(CASE WHEN LAST IS NULL OR TRIM(LAST) = '' THEN 1 ELSE 0 END) AS missing_last_name,
    SUM(CASE WHEN SUFFIX IS NULL OR TRIM(SUFFIX) = '' THEN 1 ELSE 0 END) AS missing_suffix,
    SUM(CASE WHEN MAIDEN IS NULL OR TRIM(MAIDEN) = '' THEN 1 ELSE 0 END) AS missing_maiden_name,
    SUM(CASE WHEN SSN IS NULL OR TRIM(SSN) = '' THEN 1 ELSE 0 END) AS missing_ssn,
    SUM(CASE WHEN DRIVERS IS NULL OR TRIM(DRIVERS) = '' THEN 1 ELSE 0 END) AS missing_drivers_license,
    SUM(CASE WHEN PASSPORT IS NULL OR TRIM(PASSPORT) = '' THEN 1 ELSE 0 END) AS missing_passport
FROM patients;
