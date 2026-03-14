// controllers/userController.js
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const { pool } = require('../config/database');
const { generateToken } = require('../middleware/auth');

// ─── Validation ───────────────────────────────────────────────────────────────

const validateRegister = [
  body('email')
    .trim()
    .isEmail().withMessage('A valid email address is required.')
    .normalizeEmail(),
  body('password')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters.')
    .matches(/\d/).withMessage('Password must contain at least one number.'),
];

const validateLogin = [
  body('email').trim().isEmail().withMessage('A valid email is required.').normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required.'),
];

// ─── Helpers ─────────────────────────────────────────────────────────────────

const handleValidationErrors = (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(400).json({ success: false, errors: errors.array() });
    return true;
  }
  return false;
};

// ─── Controllers ─────────────────────────────────────────────────────────────

/**
 * POST /api/users/register
 */
const register = async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  const { email, password } = req.body;

  try {
    // Check for existing user
    const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ success: false, error: 'An account with this email already exists.' });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const result = await pool.query(
      `INSERT INTO users (email, password_hash, credits)
       VALUES ($1, $2, 10)
       RETURNING id, email, credits, created_at`,
      [email, passwordHash]
    );

    const user = result.rows[0];
    const token = generateToken(user);

    return res.status(201).json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          credits: user.credits,
          createdAt: user.created_at,
        },
      },
    });
  } catch (err) {
    console.error('register error:', err);
    return res.status(500).json({ success: false, error: 'Registration failed. Please try again.' });
  }
};

/**
 * POST /api/users/login
 */
const login = async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  const { email, password } = req.body;

  try {
    const result = await pool.query(
      'SELECT id, email, password_hash, credits, created_at FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, error: 'Invalid email or password.' });
    }

    const user = result.rows[0];
    const passwordMatch = await bcrypt.compare(password, user.password_hash);

    if (!passwordMatch) {
      return res.status(401).json({ success: false, error: 'Invalid email or password.' });
    }

    const token = generateToken(user);

    return res.status(200).json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          credits: user.credits,
          createdAt: user.created_at,
        },
      },
    });
  } catch (err) {
    console.error('login error:', err);
    return res.status(500).json({ success: false, error: 'Login failed. Please try again.' });
  }
};

/**
 * GET /api/users/me
 * Returns current authenticated user's profile and credit balance.
 */
const getMe = async (req, res) => {
  const userId = req.user.id;

  try {
    const result = await pool.query(
      'SELECT id, email, credits, created_at FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found.' });
    }

    const user = result.rows[0];
    return res.status(200).json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        credits: user.credits,
        createdAt: user.created_at,
      },
    });
  } catch (err) {
    console.error('getMe error:', err);
    return res.status(500).json({ success: false, error: 'Failed to fetch user profile.' });
  }
};

module.exports = { register, login, getMe, validateRegister, validateLogin };
