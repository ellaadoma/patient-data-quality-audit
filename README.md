# Healthcare Data Quality Audit Using SQL

## Project Overview

This project uses SQL and SQLite to audit a synthetic healthcare patient dataset for common data-quality issues. The goal was to assess whether the data was complete, consistent, and formatted appropriately for analysis while identifying findings that may require further investigation.

The project follows a typical data-quality workflow: inspect the dataset, define validation rules, quantify potential issues, document findings, and distinguish confirmed results from values that require additional context.

## Objectives

- Assess missing values across the dataset.
- Check for duplicate patient IDs and identical records.
- Validate date fields and birth/death date relationships.
- Check geographic fields, coordinate ranges, and basic ZIP and FIPS formatting.
- Review numeric and financial fields for invalid formats and negative values.
- Check demographic categories and text formatting.
- Document findings, assumptions, and limitations.

## Approach and Privacy Considerations

I approached this project as an initial data-quality audit that could be adapted for a real healthcare dataset. I started by examining a subset of columns to understand the dataset's structure and develop initial validation checks. I then expanded the analysis to cover all 28 columns, building checks for missing values, duplicate records, date validity, geographic fields, numeric formats, and demographic categories.

To keep the analysis focused on data quality rather than individual patients, I used SQL queries to produce aggregate counts and summary results. I avoided including patient-level records or identifiable values in the project's findings and documentation.

Although this project uses synthetic data, I considered privacy and confidentiality throughout the workflow. In a real healthcare environment, I would follow organizational policies and applicable requirements under the Health Insurance Portability and Accountability Act (HIPAA), use only the minimum necessary information for the task where applicable, restrict access to authorized users, and avoid exposing protected health information (PHI) in query outputs, screenshots, logs, or public repositories.

## Tools and Technologies

- **SQL:** Data-quality queries, conditional logic, aggregation, grouping, and validation rules.
- **SQLite:** Local database storage and query execution.
- **Visual Studio Code:** SQL editing and project organization.
- **Git and GitHub:** Version control and project documentation.

## Dataset

The project uses the `patients.csv` file from Synthea's synthetic patient data samples.

Source: [Synthea Synthetic Patient Data Downloads](https://synthetichealth.github.io/downloads.html)

Synthea generates synthetic patient data for research, development, and testing. The dataset used in this project contains synthetic records rather than real patient records.

Although the source page labels the sample as "100 Sample Synthetic Patient Records," the downloaded CSV used in this project contained **111 data rows**, matching the number of records imported into SQLite.

The imported table contains 28 columns covering demographic information, dates, geographic fields, and healthcare-related financial values.

## Project Structure

```text
patient-data-quality-audit/
├── data/
│   └── patients.csv
├── results/
│   ├── 01_data_quality_checks.txt
│   ├── 02_missing_value_audit.txt
│   └── 03_validity_checks.txt
├── sql/
│   ├── 01_data_quality_checks.sql
│   ├── 02_missing_value_audit.sql
│   └── 03_validity_checks.sql
├── .gitignore
└── README.md
```

The SQLite database is generated locally and is not intended to be committed to the repository. The SQL scripts can be used to recreate the analysis.

## Data Quality Checks

### 1. Record and Structural Integrity

- Compared the total record count with the distinct patient ID count.
- Checked for duplicate patient IDs.
- Checked for completely identical records across all 28 columns.
- Verified the imported table's column structure.
- Compared the CSV row count with the number of imported database records.

### 2. Missing-Value Audit

Checked all 28 columns for SQL `NULL` values and blank strings, then calculated missing counts and percentages.

### 3. Date Validation

- Checked birth-date and death-date formats.
- Identified invalid, missing, or future birth dates.
- Checked for future death dates.
- Checked for death dates earlier than birth dates.
- Flagged ages over 120 at death for review.

The age threshold is a screening assumption, not proof that a record is incorrect.

### 4. Geographic Validation

- Checked latitude and longitude ranges.
- Checked whether coordinate values were missing from only one part of a coordinate pair.
- Checked basic ZIP and FIPS formatting.
- Reviewed state and county counts and text formatting.

These checks assess formatting and basic plausibility. They do not confirm that every location matches an authoritative geographic reference.

### 5. Numeric and Financial Validation

- Checked healthcare expenses, healthcare coverage, and income for negative values.
- Checked numeric fields for unexpected characters and malformed numeric formats.

These rules identify potential formatting or validity issues but do not independently establish whether a financial value is reasonable for a particular patient.

### 6. Demographic and Text Validation

- Reviewed gender, race, ethnicity, and marital-status categories.
- Checked selected text fields for leading and trailing spaces.
- Flagged marital-status values outside the selected category allowlist for review.

Unexpected or undocumented values were treated as findings for investigation rather than automatically classified as errors.

## Key Findings

The audit produced the following results:

| Check | Result |
|---|---:|
| Imported patient records | 111 |
| Columns in the imported table | 28 |
| Duplicate patient IDs detected | 0 |
| Completely identical record groups detected | 0 |
| Birth dates invalid under the selected rules | 0 |
| Death dates before birth dates | 0 |
| Future death dates | 0 |
| Records flagged for age over 120 at death | 0 |
| Invalid latitude or longitude ranges | 0 |
| Negative values in the checked financial fields | 0 |
| Invalid populated ZIP formats under the selected rule | 0 |
| Invalid populated FIPS formats under the selected rule | 0 |
| Marital-status values flagged for category review | 9 |

These findings reflect the specific validation rules used in this project. They do not establish that every value in the dataset is factually accurate.

### Missing-Value Findings

The fields with the highest missing counts were:

| Field | Missing records | Missing percentage |
|---|---:|---:|
| `SUFFIX` | 109 | 98.20% |
| `DEATHDATE` | 99 | 89.19% |
| `MAIDEN` | 79 | 71.17% |
| `MARITAL` | 44 | 39.64% |
| `FIPS` | 28 | 25.23% |
| `PASSPORT` | 27 | 24.32% |
| `MIDDLE` | 24 | 21.62% |
| `PREFIX` | 23 | 20.72% |
| `DRIVERS` | 21 | 18.92% |

The remaining 19 columns had no missing values under the audit's `NULL`-or-blank definition.

Missing values do not automatically indicate data-quality errors. For example, a missing death date may be expected for a living patient, and name suffixes may not apply to most people. Whether a field requires remediation depends on its purpose and the applicable data standards.

### Marital-Status Review

Nine populated marital-status values fell outside the `M` and `S` categories used in the selected allowlist: eight `D` values and one `W` value.

These values were flagged for documentation review, not confirmed as erroneous records. The appropriate next step would be to verify the allowed codes against the dataset documentation or with the data owner before deciding whether any correction is needed.

## How to Reproduce the Analysis

**Prerequisites:** SQLite and a terminal.

From the project root, import the CSV into a new local database:

```bash
sqlite3 healthcare.db ".mode csv" ".import data/patients.csv patients"
```

This command opens or creates `healthcare.db`, switches SQLite to CSV mode, and imports the CSV into a table named `patients`. Use a fresh database to avoid duplicate imports or conflicts with an existing table.

Run each SQL script and save its output to the corresponding results file:

```bash
sqlite3 -header -column healthcare.db < sql/01_data_quality_checks.sql > results/01_data_quality_checks.txt

sqlite3 -header -column healthcare.db < sql/02_missing_value_audit.sql > results/02_missing_value_audit.txt

sqlite3 -header -column healthcare.db < sql/03_validity_checks.sql > results/03_validity_checks.txt
```

These commands execute each SQL script against the local database. The `-header` and `-column` options make the results easier to read, while `>` redirects the output into a text file in the `results/` folder, replacing that file's previous contents.

## Next Steps with Real-World Data

If this audit were applied to real healthcare data, I would take the following steps:

1. **Confirm authorization and scope:** Work with the data owner to establish the audit's purpose, approved fields, access permissions, and applicable privacy and security requirements before accessing the data.

2. **Establish data-quality requirements:** Review the data dictionary, business rules, source systems, and stakeholder expectations to determine which values and formats are valid.

3. **Expand validation checks:** Build on the existing SQL checks to examine required fields, duplicate records, date relationships, valid ranges, category consistency, and relationships between fields.

4. **Investigate and prioritize findings:** Review aggregate results with authorized data owners to distinguish expected missing values from potential errors. Prioritize issues based on frequency, impact, and relevance to reporting or operations.

5. **Document and resolve issues:** Record each issue's description, frequency, potential impact, responsible team, and recommended corrective action. Rerun the validation checks after approved corrections are made.

6. **Develop ongoing monitoring:** Turn recurring checks into a repeatable process and track data-quality measures over time to identify persistent issues.

7. **Protect sensitive information:** Use approved, access-controlled environments and follow applicable HIPAA requirements and organizational policies. Before sharing results, ensure that outputs do not expose protected health information or create an identification risk.

## Limitations

- This analysis uses synthetic sample data and should not be interpreted as an assessment of real patient records.
- Validation rules are based on selected format expectations and assumptions; they do not prove that every value is factually accurate.
- Some missing values may be expected, optional, or not applicable.
- Category values flagged for review require context from the dataset documentation or an authorized data owner.
- ZIP and FIPS format checks do not verify geographic accuracy.
- In a production setting, confirmed issues would be prioritized by impact, investigated at the source, routed to the appropriate data owner, and rechecked after remediation.
- This project demonstrates a privacy-conscious analytical approach; it is not a formal HIPAA compliance assessment.

## Skills Demonstrated

SQL querying, data profiling, missing-value analysis, duplicate detection, conditional aggregation, date validation, text and numeric validation, documentation, privacy-conscious data handling, and communicating data-quality findings with appropriate caveats.
