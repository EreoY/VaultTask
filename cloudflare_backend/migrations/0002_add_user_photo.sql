-- Migration: Add photo_url to users table
ALTER TABLE users ADD COLUMN photo_url TEXT;
