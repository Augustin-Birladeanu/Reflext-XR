-- database/setup.sql
-- Run this manually if you prefer to set up the database schema yourself
-- instead of using `node config/database.js`

-- Create the database (run as superuser, outside of a transaction)
-- CREATE DATABASE inscape_db;

-- Connect to the database before running the rest:
-- \c inscape_db

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    email        VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    credits      INTEGER      NOT NULL DEFAULT 10,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Images table
CREATE TABLE IF NOT EXISTS images (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    prompt     TEXT        NOT NULL,
    image_url  TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_images_user_id    ON images(user_id);
CREATE INDEX IF NOT EXISTS idx_images_created_at ON images(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_email       ON users(email);

-- Verify
SELECT 'users table:' AS info, COUNT(*) FROM users;
SELECT 'images table:' AS info, COUNT(*) FROM images;
