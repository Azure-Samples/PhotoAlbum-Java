-- Migrated from Oracle to PostgreSQL according to SQL check item 1: Use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
-- PostgreSQL initialization script for photoalbum database
-- This script runs automatically when PostgreSQL container starts

-- Note: The photoalbum user is created by the POSTGRES_USER environment variable
-- We only need to grant additional privileges if required

-- Create database if not exists (though it's created by POSTGRES_DB env var)
-- The default database 'postgres' is already created

-- Grant schema privileges to photoalbum user
GRANT ALL PRIVILEGES ON DATABASE postgres TO photoalbum;

-- Grant privileges on public schema
GRANT ALL ON SCHEMA public TO photoalbum;

-- Grant default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO photoalbum;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO photoalbum;

-- Extension for UUID generation (if needed in future)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE 'PostgreSQL initialization completed successfully for photoalbum user';
END $$;

