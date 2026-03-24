// services/openaiService.js
const OpenAI = require('openai');
require('dotenv').config();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

/**
 * Generate an image from a text prompt using OpenAI Images API.
 * @param {string} prompt - The text description to generate an image from.
 * @returns {Promise<{ imageUrl: string, b64Json: string | null }>}
 */
const generateImage = async (prompt) => {
  if (!prompt || typeof prompt !== 'string') {
    throw new Error('A valid prompt string is required.');
  }

  try {
    const response = await openai.images.generate({
      model: 'gpt-image-1',
      prompt: prompt.trim(),
      n: 1,
      size: '1024x1024',
      quality: 'standard',
      // gpt-image-1 always returns b64_json, no response_format param supported
    });

    const imageData = response.data[0];

    if (!imageData) {
      throw new Error('No image data returned from OpenAI.');
    }

    // gpt-image-1 returns base64 in b64_json
    const b64Json = imageData.b64_json || null;
    const imageUrl = imageData.url || null;

    return {
      b64Json,
      imageUrl,
      revisedPrompt: imageData.revised_prompt || prompt,
    };
  } catch (err) {
    // Surface OpenAI-specific errors clearly
    if (err instanceof OpenAI.APIError) {
      throw new Error(`OpenAI API error (${err.status}): ${err.message}`);
    }
    throw err;
  }
};

module.exports = { generateImage };
