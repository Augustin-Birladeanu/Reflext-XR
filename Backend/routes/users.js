// routes/users.js
const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiter');
const {
  register,
  login,
  getMe,
  validateRegister,
  validateLogin,
} = require('../controllers/userController');

// Public routes (with auth rate limiting)
router.post('/register', authLimiter, validateRegister, register);
router.post('/login', authLimiter, validateLogin, login);

// Protected routes
router.get('/me', authenticate, getMe);

module.exports = router;
