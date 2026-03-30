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
      n: 4,
      size: '1024x1024',
      quality: 'medium',
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

/**
 * Generate symbolic insights about an image prompt using GPT.
 * @param {string} prompt - The image prompt to analyse.
 * @returns {Promise<{ insights: string }>}
 */
const generateInsights = async (prompt) => {
  if (!prompt || typeof prompt !== 'string') {
    throw new Error('A valid prompt string is required.');
  }

  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content:
            'You are an art therapist and symbolic analyst. When given an image prompt, write 2–3 sentences describing the symbolism, emotional meaning, and psychological significance of the image. Be warm, insightful, and accessible — avoid jargon.',
        },
        {
          role: 'user',
          content: `Image prompt: "${prompt.trim()}"`,
        },
      ],
      max_tokens: 200,
      temperature: 0.75,
    });

    const insights = completion.choices[0]?.message?.content?.trim() || '';
    return { insights };
  } catch (err) {
    if (err instanceof OpenAI.APIError) {
      throw new Error(`OpenAI API error (${err.status}): ${err.message}`);
    }
    throw err;
  }
};

/**
 * Generate 4 images from a text prompt in a single OpenAI call.
 * @param {string} prompt
 * @returns {Promise<Array<{ b64Json, imageUrl, revisedPrompt }>>}
 */
const generateImages = async (prompt) => {
  if (!prompt || typeof prompt !== 'string') {
    throw new Error('A valid prompt string is required.');
  }

  try {
    const response = await openai.images.generate({
      model: 'gpt-image-1',
      prompt: prompt.trim(),
      n: 4,
      size: '1024x1024',
      quality: 'medium',
    });

    if (!response.data || response.data.length === 0) {
      throw new Error('No image data returned from OpenAI.');
    }

    return response.data.map((imageData) => ({
      b64Json: imageData.b64_json || null,
      imageUrl: imageData.url || null,
      revisedPrompt: imageData.revised_prompt || prompt,
    }));
  } catch (err) {
    if (err instanceof OpenAI.APIError) {
      throw new Error(`OpenAI API error (${err.status}): ${err.message}`);
    }
    throw err;
  }
};

module.exports = { generateImage, generateImages, generateInsights };
