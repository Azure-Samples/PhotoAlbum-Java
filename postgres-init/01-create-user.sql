-- This script runs automatically when PostgreSQL container starts
-- It creates the photoalbum database and user with necessary privileges
-- Migrated from Oracle to PostgreSQL according to SQL check item 1: Use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).

-- The user and database are already created by environment variables in docker-compose.yml
-- This script performs additional setup if needed

-- Create any additional schemas or grant permissions as needed
-- Note: In PostgreSQL, the user 'photoalbum' and database 'postgres' are created via environment variables

-- Grant necessary privileges to photoalbum user
GRANT ALL PRIVILEGES ON DATABASE postgres TO photoalbum;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO photoalbum;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO photoalbum;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO photoalbum;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO photoalbum;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO photoalbum;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO photoalbum;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO photoalbum;