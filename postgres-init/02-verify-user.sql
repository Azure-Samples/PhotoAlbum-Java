-- Verification script to check if photoalbum user exists and has proper privileges
-- Migrated from Oracle to PostgreSQL according to SQL check item 1: Use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).

-- Check if user exists
SELECT usename, usecreatedb, usesuper 
FROM pg_user 
WHERE usename = 'photoalbum';

-- Show current database and user
SELECT current_database(), current_user, session_user;

-- Show granted privileges on the database
SELECT datname, datacl 
FROM pg_database 
WHERE datname = 'postgres';