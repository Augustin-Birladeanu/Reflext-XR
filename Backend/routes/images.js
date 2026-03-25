// routes/images.js
const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { generateLimiter } = require('../middleware/rateLimiter');
const {
  generateImage,
  getImages,
  getImageById,
  deleteImageById,
  validateGenerateImage,
  getInsights,
  validateGenerateInsights,
} = require('../controllers/imageController');

// All image routes require authentication
router.use(authenticate);

// POST /api/images/generate — generate a new AI image
router.post('/generate', generateLimiter, validateGenerateImage, generateImage);

// POST /api/images/insights — generate symbolic insights for a prompt (no credit cost)
router.post('/insights', validateGenerateInsights, getInsights);

// GET /api/images — list all images for authenticated user (supports ?page=&limit=)
router.get('/', getImages);

// GET /api/images/:id — get a specific image
router.get('/:id', getImageById);

// DELETE /api/images/:id — delete a specific image
router.delete('/:id', deleteImageById);

module.exports = router;
