-- Migrated from Oracle to PostgreSQL according to SQL check item 1: Use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
-- This script runs automatically when PostgreSQL container starts
-- It creates the photoalbum user and database

-- Create photoalbum user
CREATE USER photoalbum WITH PASSWORD 'photoalbum';

-- Create photoalbum database
CREATE DATABASE photoalbum WITH OWNER photoalbum;

-- Grant privileges to photoalbum user on the database
GRANT ALL PRIVILEGES ON DATABASE photoalbum TO photoalbum;

-- Connect to photoalbum database
\c photoalbum

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO photoalbum;
GRANT CREATE ON SCHEMA public TO photoalbum;

-- Grant default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO photoalbum;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO photoalbum;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO photoalbum;
