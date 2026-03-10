-- This script runs automatically when PostgreSQL container starts
-- It creates the photoalbum user and grants necessary privileges
-- Migrated from Oracle to PostgreSQL according to completeness validation

-- Create photoalbum user with password
-- In PostgreSQL, users are created with CREATE ROLE or CREATE USER
CREATE USER photoalbum WITH PASSWORD 'photoalbum';

-- Grant database privileges
-- PostgreSQL uses different privilege model than Oracle
GRANT ALL PRIVILEGES ON DATABASE photoalbum TO photoalbum;

-- Grant schema privileges (public schema by default)
GRANT ALL PRIVILEGES ON SCHEMA public TO photoalbum;

-- Grant privileges on all tables in public schema
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO photoalbum;

-- Grant privileges on all sequences in public schema
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO photoalbum;

-- Grant default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO photoalbum;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO photoalbum;

-- PostgreSQL doesn't have tablespaces in the same way Oracle does
-- Tablespaces are optional in PostgreSQL and typically not needed for basic usage

\q