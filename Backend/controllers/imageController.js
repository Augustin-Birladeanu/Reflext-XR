// controllers/imageController.js
const { body, param, validationResult } = require('express-validator');
const { pool } = require('../config/database');
const { generateImage: generateOpenAIImage, generateImages: generateOpenAIImages, generateInsights: generateOpenAIInsights, generateImageFromReflection: generateOpenAIImageFromReflection, expandReflectionToPrompt } = require('../services/openaiService');
const { uploadImage, deleteImage } = require('../services/storageService');

// ─── Validation Rules ────────────────────────────────────────────────────────

const validateGenerateImage = [
  body('prompt')
    .trim()
    .notEmpty().withMessage('Prompt is required.')
    .isLength({ min: 3, max: 4000 }).withMessage('Prompt must be between 3 and 4000 characters.'),
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
 * POST /api/images/generate
 * Generate an AI image, upload to storage, and save to database.
 */
const generateImage = async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  const { prompt } = req.body;
  const userId = req.user.id;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Check user credits
    const userResult = await client.query(
      'SELECT id, credits FROM users WHERE id = $1 FOR UPDATE',
      [userId]
    );

    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, error: 'User not found.' });
    }

    const user = userResult.rows[0];
    if (user.credits < 1) {
      await client.query('ROLLBACK');
      return res.status(402).json({
        success: false,
        error: 'Insufficient credits. Please purchase more credits to continue.',
        code: 'INSUFFICIENT_CREDITS',
      });
    }

    // 2. Call OpenAI
    let openAIResult;
    try {
      openAIResult = await generateOpenAIImage(prompt);
    } catch (err) {
      await client.query('ROLLBACK');
      return res.status(502).json({
        success: false,
        error: `Image generation failed: ${err.message}`,
      });
    }

    // 3. Upload to S3 if we got base64, otherwise use the direct URL from OpenAI
    let imageUrl;
    if (openAIResult.b64Json) {
      try {
        imageUrl = await uploadImage(openAIResult.b64Json, userId);
      } catch (err) {
        await client.query('ROLLBACK');
        return res.status(502).json({
          success: false,
          error: `Storage upload failed: ${err.message}`,
        });
      }
    } else if (openAIResult.imageUrl) {
      imageUrl = openAIResult.imageUrl;
    } else {
      await client.query('ROLLBACK');
      return res.status(502).json({
        success: false,
        error: 'No image data returned from OpenAI.',
      });
    }

    // 4. Deduct 1 credit
    await client.query(
      'UPDATE users SET credits = credits - 1, updated_at = NOW() WHERE id = $1',
      [userId]
    );

    // 5. Save image record
    const insertResult = await client.query(
      `INSERT INTO images (user_id, prompt, image_url)
       VALUES ($1, $2, $3)
       RETURNING id, user_id, prompt, image_url, created_at`,
      [userId, prompt, imageUrl]
    );

    await client.query('COMMIT');

    const image = insertResult.rows[0];
    return res.status(201).json({
      success: true,
      data: {
        id: image.id,
        prompt: image.prompt,
        url: image.image_url,
        createdAt: image.created_at,
        creditsRemaining: user.credits - 1,
        revisedPrompt: openAIResult.revisedPrompt,
      },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('generateImage error:', err);
    return res.status(500).json({ success: false, error: 'An unexpected error occurred.' });
  } finally {
    client.release();
  }
};

/**
 * GET /api/images
 * Fetch all images for the authenticated user, newest first.
 */
const getImages = async (req, res) => {
  const userId = req.user.id;
  const page = Math.max(parseInt(req.query.page) || 1, 1);
  const limit = Math.min(parseInt(req.query.limit) || 20, 100);
  const offset = (page - 1) * limit;

  try {
    const result = await pool.query(
      `SELECT id, prompt, image_url AS url, created_at AS "createdAt"
       FROM images
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    const countResult = await pool.query(
      'SELECT COUNT(*) FROM images WHERE user_id = $1',
      [userId]
    );

    const total = parseInt(countResult.rows[0].count);

    return res.status(200).json({
      success: true,
      data: result.rows,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (err) {
    console.error('getImages error:', err);
    return res.status(500).json({ success: false, error: 'Failed to fetch images.' });
  }
};

/**
 * GET /api/images/:id
 * Fetch a single image by ID (must belong to authenticated user).
 */
const getImageById = async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  try {
    const result = await pool.query(
      `SELECT id, prompt, image_url AS url, created_at AS "createdAt"
       FROM images
       WHERE id = $1 AND user_id = $2`,
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Image not found.' });
    }

    return res.status(200).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('getImageById error:', err);
    return res.status(500).json({ success: false, error: 'Failed to fetch image.' });
  }
};

/**
 * DELETE /api/images/:id
 * Delete an image (must belong to authenticated user).
 */
const deleteImageById = async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const result = await client.query(
      'SELECT id, image_url FROM images WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, error: 'Image not found.' });
    }

    const image = result.rows[0];

    // Delete from database
    await client.query('DELETE FROM images WHERE id = $1', [id]);

    // Delete from S3 (non-blocking — failure here is non-fatal)
    await deleteImage(image.image_url);

    await client.query('COMMIT');

    return res.status(200).json({ success: true, message: 'Image deleted successfully.' });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('deleteImageById error:', err);
    return res.status(500).json({ success: false, error: 'Failed to delete image.' });
  } finally {
    client.release();
  }
};

/**
 * POST /api/images/generate-batch
 * Generate 4 AI images in a single OpenAI call, upload all to storage, and save to database.
 */
const generateBatchImages = async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  const { prompt } = req.body;
  const userId = req.user.id;
  const BATCH_SIZE = 4;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const userResult = await client.query(
      'SELECT id, credits FROM users WHERE id = $1 FOR UPDATE',
      [userId]
    );

    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, error: 'User not found.' });
    }

    const user = userResult.rows[0];
    if (user.credits < BATCH_SIZE) {
      await client.query('ROLLBACK');
      return res.status(402).json({
        success: false,
        error: 'Insufficient credits. Please purchase more credits to continue.',
        code: 'INSUFFICIENT_CREDITS',
      });
    }

    let openAIResults;
    try {
      openAIResults = await generateOpenAIImages(prompt);
    } catch (err) {
      await client.query('ROLLBACK');
      return res.status(502).json({ success: false, error: `Image generation failed: ${err.message}` });
    }

    let imageUrls;
    try {
      imageUrls = await Promise.all(
        openAIResults.map((result) => {
          if (result.b64Json) return uploadImage(result.b64Json, userId);
          if (result.imageUrl) return Promise.resolve(result.imageUrl);
          throw new Error('No image data returned from OpenAI.');
        })
      );
    } catch (err) {
      await client.query('ROLLBACK');
      return res.status(502).json({ success: false, error: `Storage upload failed: ${err.message}` });
    }

    await client.query(
      'UPDATE users SET credits = credits - $1, updated_at = NOW() WHERE id = $2',
      [BATCH_SIZE, userId]
    );

    const insertResults = await Promise.all(
      imageUrls.map((url) =>
        client.query(
          `INSERT INTO images (user_id, prompt, image_url)
           VALUES ($1, $2, $3)
           RETURNING id, prompt, image_url, created_at`,
          [userId, prompt, url]
        )
      )
    );

    await client.query('COMMIT');

    const creditsRemaining = user.credits - BATCH_SIZE;
    const images = insertResults.map((r, i) => ({
      id: r.rows[0].id,
      prompt: r.rows[0].prompt,
      url: r.rows[0].image_url,
      createdAt: r.rows[0].created_at,
      creditsRemaining,
      revisedPrompt: openAIResults[i].revisedPrompt,
    }));

    return res.status(201).json({ success: true, data: images });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('generateBatchImages error:', err);
    return res.status(500).json({ success: false, error: 'An unexpected error occurred.' });
  } finally {
    client.release();
  }
};

/**
 * POST /api/images/generate-from-reflection
 * Expand a reflection statement into a symbolic prompt, generate an image, upload, and save.
 */
const generateFromReflection = async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  const { prompt } = req.body;
  const userId = req.user.id;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const userResult = await client.query(
      'SELECT id, credits FROM users WHERE id = $1 FOR UPDATE',
      [userId]
    );

    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, error: 'User not found.' });
    }

    const user = userResult.rows[0];
    if (user.credits < 1) {
      await client.query('ROLLBACK');
      return res.status(402).json({
        success: false,
        error: 'Insufficient credits. Please purchase more credits to continue.',
        code: 'INSUFFICIENT_CREDITS',
      });
    }

    let openAIResult;
    try {
      openAIResult = await generateOpenAIImageFromReflection(prompt);
    } catch (err) {
      await client.query('ROLLBACK');
      return res.status(502).json({
        success: false,
        error: `Image generation failed: ${err.message}`,
      });
    }

    let imageUrl;
    if (openAIResult.b64Json) {
      try {
        imageUrl = await uploadImage(openAIResult.b64Json, userId);
      } catch (err) {
        await client.query('ROLLBACK');
        return res.status(502).json({
          success: false,
          error: `Storage upload failed: ${err.message}`,
        });
      }
    } else if (openAIResult.imageUrl) {
      imageUrl = openAIResult.imageUrl;
    } else {
      await client.query('ROLLBACK');
      return res.status(502).json({
        success: false,
        error: 'No image data returned from OpenAI.',
      });
    }

    await client.query(
      'UPDATE users SET credits = credits - 1, updated_at = NOW() WHERE id = $1',
      [userId]
    );

    const insertResult = await client.query(
      `INSERT INTO images (user_id, prompt, image_url)
       VALUES ($1, $2, $3)
       RETURNING id, user_id, prompt, image_url, created_at`,
      [userId, prompt, imageUrl]
    );

    await client.query('COMMIT');

    const image = insertResult.rows[0];
    return res.status(201).json({
      success: true,
      data: {
        id: image.id,
        prompt: image.prompt,
        url: image.image_url,
        createdAt: image.created_at,
        creditsRemaining: user.credits - 1,
        revisedPrompt: openAIResult.revisedPrompt,
      },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('generateFromReflection error:', err);
    return res.status(500).json({ success: false, error: 'An unexpected error occurred.' });
  } finally {
    client.release();
  }
};

/**
 * POST /api/images/insights
 * Generate symbolic insights for a given prompt using GPT (no credit cost).
 */
const validateGenerateInsights = [
  body('prompt')
    .trim()
    .notEmpty().withMessage('Prompt is required.')
    .isLength({ min: 3, max: 4000 }).withMessage('Prompt must be between 3 and 4000 characters.'),
];

const getInsights = async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  const { prompt } = req.body;

  try {
    const result = await generateOpenAIInsights(prompt);
    return res.status(200).json({ success: true, data: { insights: result.insights } });
  } catch (err) {
    console.error('getInsights error:', err);
    return res.status(502).json({ success: false, error: `Insights generation failed: ${err.message}` });
  }
};

/**
 * POST /api/images/expand-reflection
 * Expand a reflection statement into an artistic prompt. No credit cost.
 */
const expandReflection = async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  const { prompt } = req.body;

  try {
    const expanded = await expandReflectionToPrompt(prompt);
    return res.status(200).json({ success: true, data: { expandedPrompt: expanded } });
  } catch (err) {
    console.error('expandReflection error:', err);
    return res.status(502).json({ success: false, error: `Expansion failed: ${err.message}` });
  }
};

module.exports = {
  generateImage,
  generateBatchImages,
  generateFromReflection,
  expandReflection,
  getImages,
  getImageById,
  deleteImageById,
  validateGenerateImage,
  getInsights,
  validateGenerateInsights,
};
