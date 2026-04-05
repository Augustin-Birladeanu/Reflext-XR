// controllers/userController.js
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { body, validationResult } = require('express-validator');
const { odata } = require('@azure/data-tables');
const { getUsersTable } = require('../config/tableStorage');
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

const findUserByEmail = async (usersTable, email) => {
  const entities = usersTable.listEntities({
    queryOptions: { filter: odata`email eq ${email}` },
  });
  for await (const entity of entities) {
    return entity;
  }
  return null;
};

// ─── Controllers ─────────────────────────────────────────────────────────────

/**
 * POST /api/users/register
 */
const register = async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  const { email, password } = req.body;

  try {
    const usersTable = getUsersTable();

    const existing = await findUserByEmail(usersTable, email);
    if (existing) {
      return res.status(409).json({ success: false, error: 'An account with this email already exists.' });
    }

    const userId = uuidv4();
    const passwordHash = await bcrypt.hash(password, 12);
    const now = new Date().toISOString();

    await usersTable.createEntity({
      partitionKey: 'users',
      rowKey: userId,
      email,
      passwordHash,
      credits: 10,
      createdAt: now,
      updatedAt: now,
    });

    const token = generateToken({ id: userId, email, credits: 10 });

    return res.status(201).json({
      success: true,
      data: {
        token,
        user: { id: userId, email, credits: 10, createdAt: now },
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
    const usersTable = getUsersTable();
    const user = await findUserByEmail(usersTable, email);

    if (!user) {
      return res.status(401).json({ success: false, error: 'Invalid email or password.' });
    }

    const passwordMatch = await bcrypt.compare(password, user.passwordHash);
    if (!passwordMatch) {
      return res.status(401).json({ success: false, error: 'Invalid email or password.' });
    }

    const token = generateToken({ id: user.rowKey, email: user.email, credits: user.credits });

    return res.status(200).json({
      success: true,
      data: {
        token,
        user: { id: user.rowKey, email: user.email, credits: user.credits, createdAt: user.createdAt },
      },
    });
  } catch (err) {
    console.error('login error:', err);
    return res.status(500).json({ success: false, error: 'Login failed. Please try again.' });
  }
};

/**
 * GET /api/users/me
 */
const getMe = async (req, res) => {
  const userId = req.user.id;

  try {
    const usersTable = getUsersTable();
    const user = await usersTable.getEntity('users', userId);

    return res.status(200).json({
      success: true,
      data: { id: user.rowKey, email: user.email, credits: user.credits, createdAt: user.createdAt },
    });
  } catch (err) {
    if (err.statusCode === 404) {
      return res.status(404).json({ success: false, error: 'User not found.' });
    }
    console.error('getMe error:', err);
    return res.status(500).json({ success: false, error: 'Failed to fetch user profile.' });
  }
};

module.exports = { register, login, getMe, validateRegister, validateLogin };
