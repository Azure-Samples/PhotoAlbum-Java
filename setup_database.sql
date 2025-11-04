-- Create application user
CREATE USER photoalbum WITH PASSWORD 'photoalbum123';

-- Grant database privileges
GRANT CONNECT ON DATABASE photoalbum TO photoalbum;

-- Grant schema privileges
GRANT ALL PRIVILEGES ON SCHEMA public TO photoalbum;

-- Grant privileges on future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO photoalbum;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO photoalbum;

-- Create the photos table for the application
CREATE TABLE IF NOT EXISTS photos (
    id VARCHAR(255) PRIMARY KEY,
    original_file_name VARCHAR(255),
    photo_data BYTEA,
    stored_file_name VARCHAR(255),
    file_path VARCHAR(500),
    file_size BIGINT,
    mime_type VARCHAR(100),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    width INTEGER,
    height INTEGER
);

-- Grant specific table permissions to application user
GRANT ALL PRIVILEGES ON TABLE photos TO photoalbum;
