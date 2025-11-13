-- Migrated from Oracle to PostgreSQL according to SQL check item 1: Use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
-- Verify photoalbum user exists and can access the database

-- Connect to photoalbum database
\c photoalbum photoalbum

-- Verify user can query
SELECT current_user, current_database();

-- List available tables (will be empty initially)
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
