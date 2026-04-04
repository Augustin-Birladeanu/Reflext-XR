// config/database.js
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'inscape_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test connection
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected database error:', err);
  process.exit(-1);
});

// Initialize tables
const initializeDatabase = async () => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Users table
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        credits INTEGER NOT NULL DEFAULT 100,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // Images table
    await client.query(`
      CREATE TABLE IF NOT EXISTS images (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        prompt TEXT NOT NULL,
        image_url TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // Index for faster user lookups
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_images_user_id ON images(user_id);
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_images_created_at ON images(created_at DESC);
    `);

    await client.query('COMMIT');
    console.log('✅ Database tables initialized successfully');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Failed to initialize database tables:', err);
    throw err;
  } finally {
    client.release();
  }
};

// Run setup if called directly: node config/database.js
if (require.main === module) {
  initializeDatabase()
    .then(() => {
      console.log('Database setup complete.');
      process.exit(0);
    })
    .catch((err) => {
      console.error('Database setup failed:', err);
      process.exit(1);
    });
}

module.exports = { pool, initializeDatabase };
