-- Migrated from Oracle to PostgreSQL according to SQL check item 1: Use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
-- Verification script to check if photoalbum user exists

-- Check if user exists
SELECT usename, usesuper, usecreatedb
FROM pg_user
WHERE usename = 'photoalbum';

-- Show database privileges
SELECT datname, datacl
FROM pg_database
WHERE datname = 'postgres';

-- Show granted privileges on schema
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'photoalbum';

