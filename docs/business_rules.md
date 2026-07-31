# Business Rules

## Overview

This document describes the transformation rules applied during the ETL process.

---

# Bronze Layer

The Bronze layer stores raw data exactly as received from the source files.

Business rules:

- No transformations are applied.
- Original column names are preserved.
- One metadata column is added:
  - Source file
  - Load timestamp

---

# Silver Layer

The Silver layer applies data cleaning and standardization.

## Data Type Conversion

The following conversions are performed:

- Order Number → INT
- Date → DATE
- Time → TIME
- Monetary values → DECIMAL(10,2)
- Quantity → INT

---

## Commerce Standardization

Several commerce names are standardized.

Example:

GB - Ilha 1
→ Ilha 1

GB - HAMBURGUERIA
→ Hamburgueria

GB - KIDS
→ Espaço Kids

Grand Bares - Bahia Varanda
→ Varanda

---

## Product Standardization

Some products are renamed.

Example:

Cerveja Itaipava Pilsen 350ml
→ Itaipava Pilsen 350ml

Black Princess
→ Black Princess 350ml

---

## Missing Values

Some placeholder values are converted into NULL.

Examples:

"-"

" "

NULL values are preserved whenever the original dataset contains missing information.

---

## Device Parsing

The original Clover device field contains two different identifiers.

The ETL separates them into:

- dispositivo_clover
- codigo_serie

---

## Event Date Extraction

The event date is extracted from the source file name.

Example:

reporte_limpo_010426.csv

↓

2026-04-01

---

# Gold Layer

The Gold layer implements a Star Schema optimized for reporting.

---

## Dimensions

The following dimensions are created:

- Product
- Device
- Event

Each dimension receives surrogate keys generated using ROW_NUMBER().

---

## Fact Tables

### fact_vendas

Contains one row per sold product.

### fact_pagamentos

Contains one row per payment.

When an order contains multiple payment methods, STRING_SPLIT() is used to create one record per payment.

---

## Filtering Rules

The analytical model excludes:

- Courtesy transactions ("Cortesía")
- Sales from the "Varanda" commerce

NULL payment methods and NULL commerce values are preserved.

---

## Referential Integrity

Dimension keys are assigned using LEFT JOIN operations between Silver and Gold layers.

---

## Load Strategy

Current implementation uses:

TRUNCATE + INSERT

for all Gold tables.

This approach guarantees a full refresh of the dimensional model after each execution.

---

# Future Improvements

Possible enhancements include:

- Incremental loading
- Slowly Changing Dimensions (SCD)
- Foreign Key constraints
- Data quality monitoring
- Automated unit tests
