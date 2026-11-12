-- Portfolio 1: create the working database.
-- Run from psql connected to the default 'postgres' database:
--   psql -U postgres -f 00_create_database.sql
-- Then connect to it with:  \c ndfs_db

DROP DATABASE IF EXISTS ndfs_db;
CREATE DATABASE ndfs_db;
