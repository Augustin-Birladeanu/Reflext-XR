// controllers/imageController.js
const { v4: uuidv4 } = require('uuid');
const { body, validationResult } = require('express-validator');
const { getUsersTable, getImagesTable } = require('../config/tableStorage');
const { generateImage: generateOpenAIImage, generateImages: generateOpenAIImages, generateInsights: generateOpenAIInsights, generateImageFromReflection: generateOpenAIImageFromReflection, expandReflectionToPrompt } = require('../services/openaiService');
const { uploadImage, deleteImage } = require('../services/storageService');

// ─── Validation Rules ────────────────────────────────────────────────────────

const validateGenerateImage = [
  body('prompt')
    .trim()
    .notEmpty().withMessage('Prompt is required.')
    .isLength({ min: 3, max: 4000 }).withMessage('Prompt must be between 3 and 4000 characters.'),
];

const validateGenerateInsights = [
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

const getUser = async (usersTable, userId) => {
  try {
    return await usersTable.getEntity('users', userId);
  } catch (err) {
    if (err.statusCode === 404) return null;
    throw err;
  }
};

const deductCredits = async (usersTable, user, amount) => {
  await usersTable.updateEntity(
    {
      partitionKey: 'users',
      rowKey: user.rowKey,
      email: user.email,
      passwordHash: user.passwordHash,
      credits: user.credits - amount,
      createdAt: user.createdAt,
      updatedAt: new Date().toISOString(),
    },
    'Replace'
  );
};

// ─── Controllers ─────────────────────────────────────────────────────────────

/**
 * POST /api/images/generate
 */
const generateImage = async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  const { prompt } = req.body;
  const userId = req.user.id;

  try {
    const usersTable = getUsersTable();
    const user = await getUser(usersTable, userId);

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found.' });
    }

    if (user.credits < 1) {
      return res.status(402).json({
        success: false,
        error: 'Insufficient credits. Please purchase more credits to continue.',
        code: 'INSUFFICIENT_CREDITS',
      });
    }

    let openAIResult;
    try {
      openAIResult = await generateOpenAIImage(prompt);
    } catch (err) {
      return res.status(502).json({ success: false, error: `Image generation failed: ${err.message}` });
    }

    let imageUrl;
    if (openAIResult.b64Json) {
      try {
        imageUrl = await uploadImage(openAIResult.b64Json, userId);
      } catch (err) {
        return res.status(502).json({ success: false, error: `Storage upload failed: ${err.message}` });
      }
    } else if (openAIResult.imageUrl) {
      imageUrl = openAIResult.imageUrl;
    } else {
      return res.status(502).json({ success: false, error: 'No image data returned from OpenAI.' });
    }

    await deductCredits(usersTable, user, 1);

    const imageId = uuidv4();
    const now = new Date().toISOString();

    return res.status(201).json({
      success: true,
      data: {
        id: imageId,
        prompt,
        url: imageUrl,
        createdAt: now,
        creditsRemaining: user.credits - 1,
        revisedPrompt: openAIResult.revisedPrompt,
      },
    });
  } catch (err) {
    console.error('generateImage error:', err);
    return res.status(500).json({ success: false, error: 'An unexpected error occurred.' });
  }
};

/**
 * GET /api/images
 */
const getImages = async (req, res) => {
  const userId = req.user.id;
  const page = Math.max(parseInt(req.query.page) || 1, 1);
  const limit = Math.min(parseInt(req.query.limit) || 20, 100);

  try {
    const imagesTable = getImagesTable();
    const allImages = [];

    const entities = imagesTable.listEntities({
      queryOptions: { filter: `PartitionKey eq '${userId}'` },
    });

    for await (const entity of entities) {
      allImages.push({
        id: entity.rowKey,
        prompt: entity.prompt,
        url: entity.imageUrl,
        createdAt: entity.createdAt,
      });
    }

    allImages.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    const total = allImages.length;
    const offset = (page - 1) * limit;
    const paged = allImages.slice(offset, offset + limit);

    return res.status(200).json({
      success: true,
      data: paged,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (err) {
    console.error('getImages error:', err);
    return res.status(500).json({ success: false, error: 'Failed to fetch images.' });
  }
};

/**
 * GET /api/images/:id
 */
const getImageById = async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  try {
    const imagesTable = getImagesTable();
    const entity = await imagesTable.getEntity(userId, id);

    return res.status(200).json({
      success: true,
      data: { id: entity.rowKey, prompt: entity.prompt, url: entity.imageUrl, createdAt: entity.createdAt },
    });
  } catch (err) {
    if (err.statusCode === 404) {
      return res.status(404).json({ success: false, error: 'Image not found.' });
    }
    console.error('getImageById error:', err);
    return res.status(500).json({ success: false, error: 'Failed to fetch image.' });
  }
};

/**
 * DELETE /api/images/:id
 */
const deleteImageById = async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  try {
    const imagesTable = getImagesTable();
    let entity;

    try {
      entity = await imagesTable.getEntity(userId, id);
    } catch (err) {
      if (err.statusCode === 404) {
        return res.status(404).json({ success: false, error: 'Image not found.' });
      }
      throw err;
    }

    await imagesTable.deleteEntity(userId, id);
    await deleteImage(entity.imageUrl);

    return res.status(200).json({ success: true, message: 'Image deleted successfully.' });
  } catch (err) {
    console.error('deleteImageById error:', err);
    return res.status(500).json({ success: false, error: 'Failed to delete image.' });
  }
};

/**
 * POST /api/images/generate-batch
 */
const generateBatchImages = async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  const { prompt } = req.body;
  const userId = req.user.id;
  const BATCH_SIZE = 4;

  try {
    const usersTable = getUsersTable();
    const user = await getUser(usersTable, userId);

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found.' });
    }

    if (user.credits < BATCH_SIZE) {
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
      return res.status(502).json({ success: false, error: `Storage upload failed: ${err.message}` });
    }

    await deductCredits(usersTable, user, BATCH_SIZE);

    const now = new Date().toISOString();
    const creditsRemaining = user.credits - BATCH_SIZE;

    const savedImages = imageUrls.map((url, i) => ({
      id: uuidv4(),
      prompt,
      url,
      createdAt: now,
      creditsRemaining,
      revisedPrompt: openAIResults[i].revisedPrompt,
    }));

    return res.status(201).json({ success: true, data: savedImages });
  } catch (err) {
    console.error('generateBatchImages error:', err);
    return res.status(500).json({ success: false, error: 'An unexpected error occurred.' });
  }
};

/**
 * POST /api/images/generate-from-reflection
 */
const generateFromReflection = async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  const { prompt } = req.body;
  const userId = req.user.id;

  try {
    const usersTable = getUsersTable();
    const user = await getUser(usersTable, userId);

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found.' });
    }

    if (user.credits < 1) {
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
      return res.status(502).json({ success: false, error: `Image generation failed: ${err.message}` });
    }

    let imageUrl;
    if (openAIResult.b64Json) {
      try {
        imageUrl = await uploadImage(openAIResult.b64Json, userId);
      } catch (err) {
        return res.status(502).json({ success: false, error: `Storage upload failed: ${err.message}` });
      }
    } else if (openAIResult.imageUrl) {
      imageUrl = openAIResult.imageUrl;
    } else {
      return res.status(502).json({ success: false, error: 'No image data returned from OpenAI.' });
    }

    await deductCredits(usersTable, user, 1);

    const imageId = uuidv4();
    const now = new Date().toISOString();

    return res.status(201).json({
      success: true,
      data: {
        id: imageId,
        prompt,
        url: imageUrl,
        createdAt: now,
        creditsRemaining: user.credits - 1,
        revisedPrompt: openAIResult.revisedPrompt,
      },
    });
  } catch (err) {
    console.error('generateFromReflection error:', err);
    return res.status(500).json({ success: false, error: 'An unexpected error occurred.' });
  }
};

/**
 * POST /api/images/save
 * Save a generated image to the user's library.
 */
const saveImage = async (req, res) => {
  const { id, prompt, url, revisedPrompt } = req.body;
  const userId = req.user.id;

  if (!id || !prompt || !url) {
    return res.status(400).json({ success: false, error: 'id, prompt, and url are required.' });
  }

  try {
    const imagesTable = getImagesTable();

    // Check if already saved
    try {
      await imagesTable.getEntity(userId, id);
      return res.status(409).json({ success: false, error: 'Image already saved.' });
    } catch (err) {
      if (err.statusCode !== 404) throw err;
    }

    const now = new Date().toISOString();
    await imagesTable.createEntity({
      partitionKey: userId,
      rowKey: id,
      prompt,
      imageUrl: url,
      revisedPrompt: revisedPrompt || '',
      createdAt: now,
    });

    return res.status(201).json({
      success: true,
      data: { id, prompt, url, createdAt: now },
    });
  } catch (err) {
    console.error('saveImage error:', err);
    return res.status(500).json({ success: false, error: 'Failed to save image.' });
  }
};

/**
 * POST /api/images/insights
 */
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
  saveImage,
  getImages,
  getImageById,
  deleteImageById,
  validateGenerateImage,
  getInsights,
  validateGenerateInsights,
};
