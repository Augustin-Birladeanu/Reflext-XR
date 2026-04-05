// routes/images.js
const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { generateLimiter } = require('../middleware/rateLimiter');
const {
  generateImage,
  generateBatchImages,
  generateFromReflection,
  expandReflection,
  saveImage,
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

// POST /api/images/generate-batch — generate 4 AI images in one OpenAI call
router.post('/generate-batch', generateLimiter, validateGenerateImage, generateBatchImages);

// POST /api/images/generate-from-reflection — expand reflection then generate a single image
router.post('/generate-from-reflection', generateLimiter, validateGenerateImage, generateFromReflection);

// POST /api/images/expand-reflection — expand reflection to artistic prompt, no credit cost
router.post('/expand-reflection', validateGenerateImage, expandReflection);

// POST /api/images/insights — generate symbolic insights for a prompt (no credit cost)
router.post('/insights', validateGenerateInsights, getInsights);

// POST /api/images/save — save a generated image to the user's library
router.post('/save', saveImage);

// GET /api/images — list all images for authenticated user (supports ?page=&limit=)
router.get('/', getImages);

// GET /api/images/:id — get a specific image
router.get('/:id', getImageById);

// DELETE /api/images/:id — delete a specific image
router.delete('/:id', deleteImageById);

module.exports = router;
