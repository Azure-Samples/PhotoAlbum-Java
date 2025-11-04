-- Migrated from Oracle to PostgreSQL according to SQL check item 1: Use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
-- Verification script to check if photoalbum user exists

-- Check if user exists in PostgreSQL
SELECT 
    usename AS username, 
    usesuper AS is_superuser,
    usecreatedb AS can_create_db,
    usebypassrls AS can_bypass_rls
FROM pg_user 
WHERE usename = 'photoalbum';

-- Show databases accessible to the user
SELECT datname AS database_name
FROM pg_database 
WHERE datname = 'postgres';