# Application Migration Guidance

⚠️ **Note**: This is basic guidance generated during export. For enhanced analysis, run the migration summarizing agent.

Generated for project: rujche-migration-project-1113
Generated on: 2025-11-13T10:02:16.093765

## Overview

This document provides basic guidance for updating your application to work with the migrated PostgreSQL database.

## Migration Summary

- **Total Objects**: 3
- **Conversion Rate**: Unknown%
- **Total Chunks**: 1
- **Completed Chunks**: 1

## Migration Notes

### Data_Type_Mapping
**Impact**: high
**Summary**: Oracle NUMBER(19,0) and NUMBER(10,0) columns converted to PostgreSQL BIGINT for file_size, height, and width columns to optimize for integer storage and performance.
**Affected Objects**: PHOTOALBUM.PHOTOS
Oracle NUMBER(19,0) and NUMBER(10,0) columns in PHOTOALBUM.PHOTOS were mapped to PostgreSQL BIGINT instead of the default NUMERIC type. This was done to optimize for integer storage and performance, as BIGINT is more efficient for large integer values in PostgreSQL.

### Data_Type_Mapping
**Impact**: high
**Summary**: Oracle BLOB column for photo_data converted to PostgreSQL BYTEA, as PostgreSQL does not support BLOB natively and BYTEA is the standard binary storage type.
**Affected Objects**: PHOTOALBUM.PHOTOS
The photo_data column in PHOTOALBUM.PHOTOS was mapped from Oracle BLOB to PostgreSQL BYTEA. PostgreSQL does not have a native BLOB type, and BYTEA is the recommended type for binary data storage.

### Default_Value_Mapping
**Impact**: medium
**Summary**: Oracle SYSTIMESTAMP default for uploaded_at column replaced with PostgreSQL CURRENT_TIMESTAMP to provide equivalent automatic timestamping behavior.
**Affected Objects**: PHOTOALBUM.PHOTOS
The uploaded_at column in PHOTOALBUM.PHOTOS used Oracle SYSTIMESTAMP as a default value. In PostgreSQL, this was replaced with CURRENT_TIMESTAMP to maintain automatic timestamping functionality.

### Schema_Structure
**Impact**: low
**Summary**: Oracle schema created explicitly in PostgreSQL using CREATE SCHEMA, as Oracle schemas are user-based and PostgreSQL requires explicit schema creation.
**Affected Objects**: PHOTOALBUM.PHOTOALBUM
The PHOTOALBUM schema was created in PostgreSQL using CREATE SCHEMA. Unlike Oracle, where schemas are tied to users, PostgreSQL requires explicit schema creation for organizational purposes.

