-- File: 03_validity_checks.sql
-- Purpose: Identifying geographic coordinates outside valid ranges.
-- Dataset: Synthea synthetic patient records

-- Check 1: Validating latitude and longitude ranges.
-- Latitude must be between -90 and 90.
-- Longitude must be between -180 and 180.
-- Missing values are excluded from these checks.

SELECT
    SUM(
        CASE
            WHEN LAT IS NOT NULL
                 AND TRIM(LAT) <> ''
                 AND (CAST(LAT AS REAL) < -90
                      OR CAST(LAT AS REAL) > 90)
            THEN 1
            ELSE 0
        END
    ) AS invalid_latitudes,

    SUM(
        CASE
            WHEN LON IS NOT NULL
                 AND TRIM(LON) <> ''
                 AND (CAST(LON AS REAL) < -180
                      OR CAST(LON AS REAL) > 180)
            THEN 1
            ELSE 0
        END
    ) AS invalid_longitudes
FROM patients;

-- Check 2: Identifying negative financial values.
-- Flagging negative values for review, not automatically classified as errors.
-- Missing or blank values are excluded.

SELECT
    SUM(
        CASE
            WHEN TRIM(HEALTHCARE_EXPENSES) <> ''
                 AND HEALTHCARE_EXPENSES IS NOT NULL
                 AND CAST(HEALTHCARE_EXPENSES AS REAL) < 0
            THEN 1
            ELSE 0
        END
    ) AS negative_healthcare_expenses,

    SUM(
        CASE
            WHEN TRIM(HEALTHCARE_COVERAGE) <> ''
                 AND HEALTHCARE_COVERAGE IS NOT NULL
                 AND CAST(HEALTHCARE_COVERAGE AS REAL) < 0
            THEN 1
            ELSE 0
        END
    ) AS negative_healthcare_coverage,

    SUM(
        CASE
            WHEN TRIM(INCOME) <> ''
                 AND INCOME IS NOT NULL
                 AND CAST(INCOME AS REAL) < 0
            THEN 1
            ELSE 0
        END
    ) AS negative_income
FROM patients;

-- Check 3: Reviewing distinct values in demographic fields.
-- This helps identify unexpected categories or inconsistent coding.
-- Values are counted rather than displaying individual patient records.

SELECT
    'GENDER' AS field_name,
    COALESCE(NULLIF(TRIM(GENDER), ''), '[Missing]') AS field_value,
    COUNT(*) AS record_count
FROM patients
GROUP BY COALESCE(NULLIF(TRIM(GENDER), ''), '[Missing]')

UNION ALL

SELECT
    'MARITAL' AS field_name,
    COALESCE(NULLIF(TRIM(MARITAL), ''), '[Missing]') AS field_value,
    COUNT(*) AS record_count
FROM patients
GROUP BY COALESCE(NULLIF(TRIM(MARITAL), ''), '[Missing]')

ORDER BY field_name, field_value;

-- Check 4: Review distinct race and ethnicity categories.
-- Counting each category to identify unexpected or inconsistent values.
-- Do not display individual patient records.

SELECT
    'RACE' AS field_name,
    COALESCE(NULLIF(TRIM(RACE), ''), '[Missing]') AS field_value,
    COUNT(*) AS record_count
FROM patients
GROUP BY COALESCE(NULLIF(TRIM(RACE), ''), '[Missing]')

UNION ALL

SELECT
    'ETHNICITY' AS field_name,
    COALESCE(NULLIF(TRIM(ETHNICITY), ''), '[Missing]') AS field_value,
    COUNT(*) AS record_count
FROM patients
GROUP BY COALESCE(NULLIF(TRIM(ETHNICITY), ''), '[Missing]')

ORDER BY field_name, field_value;

-- Check 5: Identifying ZIP codes that do not follow a basic
-- five-digit format.
-- This is a preliminary format check, not proof that a ZIP code exists.

SELECT
    SUM(
        CASE
            WHEN ZIP IS NOT NULL
                 AND TRIM(ZIP) <> ''
                 AND (
                     LENGTH(TRIM(ZIP)) <> 5
                     OR TRIM(ZIP) GLOB '*[^0-9]*'
                 )
            THEN 1
            ELSE 0
        END
    ) AS invalid_zip_format_count
FROM patients;

-- Check 6: Review the format of populated FIPS codes.
-- This checks for five-digit numeric values.
-- Missing values are excluded because they were counted separately in the missing-value audit.
-- Confirm the expected format against the dataset documentation.

SELECT
    SUM(
        CASE
            WHEN FIPS IS NOT NULL
                 AND TRIM(FIPS) <> ''
                 AND (
                     LENGTH(TRIM(FIPS)) <> 5
                     OR TRIM(FIPS) GLOB '*[^0-9]*'
                 )
            THEN 1
            ELSE 0
        END
    ) AS invalid_fips_format_count,

    SUM(
        CASE
            WHEN FIPS IS NOT NULL
                 AND TRIM(FIPS) <> ''
            THEN 1
            ELSE 0
        END
    ) AS populated_fips_count
FROM patients;

-- Check 7: Summarizing geographic categories.
-- Counting distinct state and county values to support a later review of geographic consistency.
-- No patient-level addresses are displayed.

SELECT
    'STATE' AS field_name,
    COUNT(DISTINCT TRIM(STATE)) AS distinct_value_count,
    SUM(
        CASE
            WHEN STATE IS NULL OR TRIM(STATE) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_count
FROM patients

UNION ALL

SELECT
    'COUNTY' AS field_name,
    COUNT(DISTINCT TRIM(COUNTY)) AS distinct_value_count,
    SUM(
        CASE
            WHEN COUNTY IS NULL OR TRIM(COUNTY) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_count
FROM patients;

-- Check 8: Identifying state and county values with leading or trailing spaces.
-- These spaces can cause matching and grouping problems.

SELECT
    SUM(
        CASE
            WHEN STATE IS NOT NULL
                 AND STATE <> TRIM(STATE)
            THEN 1
            ELSE 0
        END
    ) AS state_values_with_extra_spaces,

    SUM(
        CASE
            WHEN COUNTY IS NOT NULL
                 AND COUNTY <> TRIM(COUNTY)
            THEN 1
            ELSE 0
        END
    ) AS county_values_with_extra_spaces
FROM patients;

-- Check 9: Identify non-numeric characters in financial fields.
-- Expected format: digits with an optional decimal point.
-- Missing values are excluded because they are audited separately.
-- This is a preliminary format check, not a full financial validation.

SELECT
    SUM(
        CASE
            WHEN HEALTHCARE_EXPENSES IS NOT NULL
                 AND TRIM(HEALTHCARE_EXPENSES) <> ''
                 AND TRIM(HEALTHCARE_EXPENSES) GLOB '*[^0-9.]*'
            THEN 1
            ELSE 0
        END
    ) AS expenses_with_unexpected_characters,

    SUM(
        CASE
            WHEN HEALTHCARE_COVERAGE IS NOT NULL
                 AND TRIM(HEALTHCARE_COVERAGE) <> ''
                 AND TRIM(HEALTHCARE_COVERAGE) GLOB '*[^0-9.]*'
            THEN 1
            ELSE 0
        END
    ) AS coverage_with_unexpected_characters,

    SUM(
        CASE
            WHEN INCOME IS NOT NULL
                 AND TRIM(INCOME) <> ''
                 AND TRIM(INCOME) GLOB '*[^0-9.]*'
            THEN 1
            ELSE 0
        END
    ) AS income_with_unexpected_characters
FROM patients;

-- Check 10: Identify leading or trailing spaces in name fields.
-- Names are not displayed; only issue counts are returned.
-- Missing values are excluded from this formatting check.

SELECT
    SUM(
        CASE
            WHEN FIRST IS NOT NULL
                 AND FIRST <> TRIM(FIRST)
            THEN 1 ELSE 0
        END
    ) AS first_name_spacing_issues,

    SUM(
        CASE
            WHEN MIDDLE IS NOT NULL
                 AND MIDDLE <> TRIM(MIDDLE)
            THEN 1 ELSE 0
        END
    ) AS middle_name_spacing_issues,

    SUM(
        CASE
            WHEN LAST IS NOT NULL
                 AND LAST <> TRIM(LAST)
            THEN 1 ELSE 0
        END
    ) AS last_name_spacing_issues,

    SUM(
        CASE
            WHEN MAIDEN IS NOT NULL
                 AND MAIDEN <> TRIM(MAIDEN)
            THEN 1 ELSE 0
        END
    ) AS maiden_name_spacing_issues
FROM patients;

-- Check 11: Identify leading or trailing spaces in identifier fields.
-- Only aggregate counts are returned; identifier values are never displayed.
-- This checks formatting, not whether identifiers are valid or authentic.

SELECT
    SUM(
        CASE
            WHEN SSN IS NOT NULL
                 AND SSN <> TRIM(SSN)
            THEN 1 ELSE 0
        END
    ) AS ssn_spacing_issues,

    SUM(
        CASE
            WHEN DRIVERS IS NOT NULL
                 AND DRIVERS <> TRIM(DRIVERS)
            THEN 1 ELSE 0
        END
    ) AS drivers_license_spacing_issues,

    SUM(
        CASE
            WHEN PASSPORT IS NOT NULL
                 AND PASSPORT <> TRIM(PASSPORT)
            THEN 1 ELSE 0
        END
    ) AS passport_spacing_issues
FROM patients;

-- Check 12: Identify leading or trailing spaces in birthplace values.
-- Return aggregate counts only; do not display individual records.

SELECT
    SUM(
        CASE
            WHEN BIRTHPLACE IS NOT NULL
                 AND BIRTHPLACE <> TRIM(BIRTHPLACE)
            THEN 1
            ELSE 0
        END
    ) AS birthplace_spacing_issues
FROM patients;

-- Check 13: Check address and location fields for extra spaces.
-- Return counts only; do not display patient addresses.

SELECT
    SUM(CASE
        WHEN ADDRESS IS NOT NULL AND ADDRESS <> TRIM(ADDRESS)
        THEN 1 ELSE 0
    END) AS address_spacing_issues,

    SUM(CASE
        WHEN CITY IS NOT NULL AND CITY <> TRIM(CITY)
        THEN 1 ELSE 0
    END) AS city_spacing_issues,

    SUM(CASE
        WHEN STATE IS NOT NULL AND STATE <> TRIM(STATE)
        THEN 1 ELSE 0
    END) AS state_spacing_issues,

    SUM(CASE
        WHEN COUNTY IS NOT NULL AND COUNTY <> TRIM(COUNTY)
        THEN 1 ELSE 0
    END) AS county_spacing_issues,

    SUM(CASE
        WHEN ZIP IS NOT NULL AND ZIP <> TRIM(ZIP)
        THEN 1 ELSE 0
    END) AS zip_spacing_issues
FROM patients;

-- Check 14: Review numeric fields for unexpected characters.
-- Applies to latitude, longitude, healthcare expenses,
-- healthcare coverage, and income.
-- This is a preliminary format check, not full numeric validation.

SELECT
    SUM(CASE
        WHEN LAT IS NOT NULL
             AND TRIM(LAT) <> ''
             AND TRIM(LAT) GLOB '*[^0-9.-]*'
        THEN 1 ELSE 0
    END) AS latitude_unexpected_characters,

    SUM(CASE
        WHEN LON IS NOT NULL
             AND TRIM(LON) <> ''
             AND TRIM(LON) GLOB '*[^0-9.-]*'
        THEN 1 ELSE 0
    END) AS longitude_unexpected_characters,

    SUM(CASE
        WHEN HEALTHCARE_EXPENSES IS NOT NULL
             AND TRIM(HEALTHCARE_EXPENSES) <> ''
             AND TRIM(HEALTHCARE_EXPENSES) GLOB '*[^0-9.-]*'
        THEN 1 ELSE 0
    END) AS expenses_unexpected_characters,

    SUM(CASE
        WHEN HEALTHCARE_COVERAGE IS NOT NULL
             AND TRIM(HEALTHCARE_COVERAGE) <> ''
             AND TRIM(HEALTHCARE_COVERAGE) GLOB '*[^0-9.-]*'
        THEN 1 ELSE 0
    END) AS coverage_unexpected_characters,

    SUM(CASE
        WHEN INCOME IS NOT NULL
             AND TRIM(INCOME) <> ''
             AND TRIM(INCOME) GLOB '*[^0-9.-]*'
        THEN 1 ELSE 0
    END) AS income_unexpected_characters
FROM patients;

-- Check 15: Identify records with only one coordinate populated.
-- A usable coordinate pair normally requires both latitude
-- and longitude.
-- This flags incomplete pairs without displaying patient locations.

SELECT
    SUM(
        CASE
            WHEN LAT IS NOT NULL
                 AND TRIM(LAT) <> ''
                 AND (
                     LON IS NULL
                     OR TRIM(LON) = ''
                 )
            THEN 1
            ELSE 0
        END
    ) AS latitude_without_longitude,

    SUM(
        CASE
            WHEN LON IS NOT NULL
                 AND TRIM(LON) <> ''
                 AND (
                     LAT IS NULL
                     OR TRIM(LAT) = ''
                 )
            THEN 1
            ELSE 0
        END
    ) AS longitude_without_latitude
FROM patients;

-- Check 16: Validate the structure of numeric values.
-- Allowed format: optional leading minus sign, digits,
-- and an optional decimal point followed by digits.
-- Examples of invalid formats include 12..5, 12-3, and abc.
-- Missing values are excluded and handled by the missing-value audit.

SELECT
    'LAT' AS field_name,
    SUM(CASE
        WHEN LAT IS NOT NULL AND TRIM(LAT) <> ''
             AND (
                 TRIM(LAT) GLOB '*[^0-9.-]*'
                 OR LENGTH(TRIM(LAT))
                    - LENGTH(REPLACE(TRIM(LAT), '.', '')) > 1
                 OR (
                     INSTR(TRIM(LAT), '-') > 0
                     AND (
                         INSTR(TRIM(LAT), '-') <> 1
                         OR LENGTH(TRIM(LAT))
                            - LENGTH(REPLACE(TRIM(LAT), '-', '')) > 1
                     )
                 )
                 OR REPLACE(REPLACE(TRIM(LAT), '.', ''), '-', '') = ''
                 OR SUBSTR(TRIM(LAT), 1, 1) = '.'
                 OR SUBSTR(TRIM(LAT), -1, 1) = '.'
             )
        THEN 1 ELSE 0
    END) AS malformed_count
FROM patients

UNION ALL

SELECT
    'LON',
    SUM(CASE
        WHEN LON IS NOT NULL AND TRIM(LON) <> ''
             AND (
                 TRIM(LON) GLOB '*[^0-9.-]*'
                 OR LENGTH(TRIM(LON))
                    - LENGTH(REPLACE(TRIM(LON), '.', '')) > 1
                 OR (
                     INSTR(TRIM(LON), '-') > 0
                     AND (
                         INSTR(TRIM(LON), '-') <> 1
                         OR LENGTH(TRIM(LON))
                            - LENGTH(REPLACE(TRIM(LON), '-', '')) > 1
                     )
                 )
                 OR REPLACE(REPLACE(TRIM(LON), '.', ''), '-', '') = ''
                 OR SUBSTR(TRIM(LON), 1, 1) = '.'
                 OR SUBSTR(TRIM(LON), -1, 1) = '.'
             )
        THEN 1 ELSE 0
    END)
FROM patients

UNION ALL

SELECT
    'HEALTHCARE_EXPENSES',
    SUM(CASE
        WHEN HEALTHCARE_EXPENSES IS NOT NULL
             AND TRIM(HEALTHCARE_EXPENSES) <> ''
             AND (
                 TRIM(HEALTHCARE_EXPENSES) GLOB '*[^0-9.-]*'
                 OR LENGTH(TRIM(HEALTHCARE_EXPENSES))
                    - LENGTH(REPLACE(TRIM(HEALTHCARE_EXPENSES), '.', '')) > 1
                 OR (
                     INSTR(TRIM(HEALTHCARE_EXPENSES), '-') > 0
                     AND (
                         INSTR(TRIM(HEALTHCARE_EXPENSES), '-') <> 1
                         OR LENGTH(TRIM(HEALTHCARE_EXPENSES))
                            - LENGTH(REPLACE(TRIM(HEALTHCARE_EXPENSES), '-', '')) > 1
                     )
                 )
                 OR REPLACE(REPLACE(TRIM(HEALTHCARE_EXPENSES), '.', ''), '-', '') = ''
                 OR SUBSTR(TRIM(HEALTHCARE_EXPENSES), 1, 1) = '.'
                 OR SUBSTR(TRIM(HEALTHCARE_EXPENSES), -1, 1) = '.'
             )
        THEN 1 ELSE 0
    END)
FROM patients

UNION ALL

SELECT
    'HEALTHCARE_COVERAGE',
    SUM(CASE
        WHEN HEALTHCARE_COVERAGE IS NOT NULL
             AND TRIM(HEALTHCARE_COVERAGE) <> ''
             AND (
                 TRIM(HEALTHCARE_COVERAGE) GLOB '*[^0-9.-]*'
                 OR LENGTH(TRIM(HEALTHCARE_COVERAGE))
                    - LENGTH(REPLACE(TRIM(HEALTHCARE_COVERAGE), '.', '')) > 1
                 OR (
                     INSTR(TRIM(HEALTHCARE_COVERAGE), '-') > 0
                     AND (
                         INSTR(TRIM(HEALTHCARE_COVERAGE), '-') <> 1
                         OR LENGTH(TRIM(HEALTHCARE_COVERAGE))
                            - LENGTH(REPLACE(TRIM(HEALTHCARE_COVERAGE), '-', '')) > 1
                     )
                 )
                 OR REPLACE(REPLACE(TRIM(HEALTHCARE_COVERAGE), '.', ''), '-', '') = ''
                 OR SUBSTR(TRIM(HEALTHCARE_COVERAGE), 1, 1) = '.'
                 OR SUBSTR(TRIM(HEALTHCARE_COVERAGE), -1, 1) = '.'
             )
        THEN 1 ELSE 0
    END)
FROM patients

UNION ALL

SELECT
    'INCOME',
    SUM(CASE
        WHEN INCOME IS NOT NULL AND TRIM(INCOME) <> ''
             AND (
                 TRIM(INCOME) GLOB '*[^0-9.-]*'
                 OR LENGTH(TRIM(INCOME))
                    - LENGTH(REPLACE(TRIM(INCOME), '.', '')) > 1
                 OR (
                     INSTR(TRIM(INCOME), '-') > 0
                     AND (
                         INSTR(TRIM(INCOME), '-') <> 1
                         OR LENGTH(TRIM(INCOME))
                            - LENGTH(REPLACE(TRIM(INCOME), '-', '')) > 1
                     )
                 )
                 OR REPLACE(REPLACE(TRIM(INCOME), '.', ''), '-', '') = ''
                 OR SUBSTR(TRIM(INCOME), 1, 1) = '.'
                 OR SUBSTR(TRIM(INCOME), -1, 1) = '.'
             )
        THEN 1 ELSE 0
    END)
FROM patients
ORDER BY field_name;

-- Check 17: Flag death dates that occur after today's date.
-- Missing death dates are excluded because they may indicate
-- that the patient is alive.
-- This rule uses the current date and is therefore time-dependent.

SELECT
    SUM(
        CASE
            WHEN DEATHDATE IS NOT NULL
                 AND TRIM(DEATHDATE) <> ''
                 AND date(DEATHDATE) > date('now')
            THEN 1
            ELSE 0
        END
    ) AS future_death_dates
FROM patients;

-- Check 18: Validate date format and calendar-date consistency.
-- Expected format: YYYY-MM-DD.
-- Missing death dates are allowed and are excluded from this check.
-- The query returns counts only, not patient-level dates.

SELECT
    SUM(
        CASE
            WHEN BIRTHDATE IS NOT NULL
                 AND TRIM(BIRTHDATE) <> ''
                 AND (
                     LENGTH(TRIM(BIRTHDATE)) <> 10
                     OR SUBSTR(TRIM(BIRTHDATE), 5, 1) <> '-'
                     OR SUBSTR(TRIM(BIRTHDATE), 8, 1) <> '-'
                     OR date(BIRTHDATE) IS NULL
                     OR date(BIRTHDATE) <> TRIM(BIRTHDATE)
                 )
            THEN 1
            ELSE 0
        END
    ) AS invalid_birthdate_format_or_calendar,

    SUM(
        CASE
            WHEN DEATHDATE IS NOT NULL
                 AND TRIM(DEATHDATE) <> ''
                 AND (
                     LENGTH(TRIM(DEATHDATE)) <> 10
                     OR SUBSTR(TRIM(DEATHDATE), 5, 1) <> '-'
                     OR SUBSTR(TRIM(DEATHDATE), 8, 1) <> '-'
                     OR date(DEATHDATE) IS NULL
                     OR date(DEATHDATE) <> TRIM(DEATHDATE)
                 )
            THEN 1
            ELSE 0
        END
    ) AS invalid_deathdate_format_or_calendar
FROM patients;

-- Check 19: Review birth/death date relationships.
-- Flag death dates before birth dates.
-- Also flag ages over 120 at death for manual review.
-- The 120-year threshold is a screening assumption,
-- not proof that a record is incorrect.

SELECT
    SUM(
        CASE
            WHEN DEATHDATE IS NOT NULL
                 AND TRIM(DEATHDATE) <> ''
                 AND date(DEATHDATE) < date(BIRTHDATE)
            THEN 1
            ELSE 0
        END
    ) AS death_before_birth_count,

    SUM(
        CASE
            WHEN DEATHDATE IS NOT NULL
                 AND TRIM(DEATHDATE) <> ''
                 AND date(DEATHDATE) >= date(BIRTHDATE)
                 AND (
                     CAST(strftime('%Y', DEATHDATE) AS INTEGER)
                     - CAST(strftime('%Y', BIRTHDATE) AS INTEGER) > 120
                     OR (
                         CAST(strftime('%Y', DEATHDATE) AS INTEGER)
                         - CAST(strftime('%Y', BIRTHDATE) AS INTEGER) = 120
                         AND strftime('%m-%d', DEATHDATE)
                             < strftime('%m-%d', BIRTHDATE)
                     )
                 )
            THEN 1
            ELSE 0
        END
    ) AS deaths_after_age_120
FROM patients;

-- Check 20: Count demographic values with leading or trailing spaces.
-- TRIM removes spaces from the beginning and end of a string.
-- We return counts only, not individual records.

SELECT
    SUM(
        CASE
            WHEN GENDER IS NOT NULL
                 AND GENDER <> TRIM(GENDER)
            THEN 1 ELSE 0
        END
    ) AS gender_spacing_issues,

    SUM(
        CASE
            WHEN RACE IS NOT NULL
                 AND RACE <> TRIM(RACE)
            THEN 1 ELSE 0
        END
    ) AS race_spacing_issues,

    SUM(
        CASE
            WHEN ETHNICITY IS NOT NULL
                 AND ETHNICITY <> TRIM(ETHNICITY)
            THEN 1 ELSE 0
        END
    ) AS ethnicity_spacing_issues,

    SUM(
        CASE
            WHEN MARITAL IS NOT NULL
                 AND MARITAL <> TRIM(MARITAL)
            THEN 1 ELSE 0
        END
    ) AS marital_spacing_issues
FROM patients;

-- Check 21: Count demographic values outside documented categories.
-- These rules are based on the Synthea data dictionary.
-- Unexpected values are flagged for review, not automatically changed.

SELECT
    SUM(
        CASE
            WHEN GENDER IS NOT NULL
                 AND TRIM(GENDER) <> ''
                 AND UPPER(TRIM(GENDER)) NOT IN ('M', 'F')
            THEN 1 ELSE 0
        END
    ) AS unexpected_gender_count,

    SUM(
        CASE
            WHEN MARITAL IS NOT NULL
                 AND TRIM(MARITAL) <> ''
                 AND UPPER(TRIM(MARITAL)) NOT IN ('M', 'S')
            THEN 1 ELSE 0
        END
    ) AS marital_values_needing_review
FROM patients;

-- Check 22: Review race and ethnicity categories.
-- GROUP BY combines records with the same category.
-- COUNT(*) shows how many records belong to each category.

SELECT
    'RACE' AS field_name,
    COALESCE(NULLIF(TRIM(RACE), ''), '[Missing]') AS category,
    COUNT(*) AS record_count
FROM patients
GROUP BY COALESCE(NULLIF(TRIM(RACE), ''), '[Missing]')

UNION ALL

SELECT
    'ETHNICITY' AS field_name,
    COALESCE(NULLIF(TRIM(ETHNICITY), ''), '[Missing]') AS category,
    COUNT(*) AS record_count
FROM patients
GROUP BY COALESCE(NULLIF(TRIM(ETHNICITY), ''), '[Missing]')

ORDER BY field_name, category;

-- Check 23: Count duplicate full records.
-- GROUP BY compares every column across the table.
-- HAVING keeps only groups that appear more than once.
-- The outer query counts how many duplicate groups exist.

SELECT
    COUNT(*) AS duplicate_record_groups
FROM (
    SELECT *
    FROM patients
    GROUP BY
        Id, BIRTHDATE, DEATHDATE, SSN, DRIVERS, PASSPORT,
        PREFIX, FIRST, MIDDLE, LAST, SUFFIX, MAIDEN,
        MARITAL, RACE, ETHNICITY, GENDER, BIRTHPLACE,
        ADDRESS, CITY, STATE, COUNTY, FIPS, ZIP, LAT, LON,
        HEALTHCARE_EXPENSES, HEALTHCARE_COVERAGE, INCOME
    HAVING COUNT(*) > 1
);
