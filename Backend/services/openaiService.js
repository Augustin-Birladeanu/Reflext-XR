// services/openaiService.js
const OpenAI = require('openai');
require('dotenv').config();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});


const WELLNESS_PREFIX = 'A beautiful, uplifting, therapeutic wellness artwork. ';
const NO_TEXT_SUFFIX = ' No text, words, letters, numbers, or typography anywhere in the image.';

/**
 * Use GPT to rewrite a prompt with any potentially flagged words removed or softened.
 * @param {string} prompt
 * @returns {Promise<string>}
 */
const simplifySafetyRetry = async (prompt) => {
  const completion = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content:
          'You are helping rewrite image prompts for a wellness app so they pass safety filters. ' +
          'Rewrite the prompt to remove or soften any words that could be flagged (e.g. darkness, ashes, fire, broken, anger, death, burning) ' +
          'while preserving the emotional and symbolic meaning. Keep it gentle, poetic, and metaphorical. ' +
          'Return only the rewritten prompt, nothing else.',
      },
      { role: 'user', content: prompt },
    ],
    max_tokens: 200,
    temperature: 0.5,
  });
  return completion.choices[0]?.message?.content?.trim() || prompt;
};

/**
 * Call the OpenAI image generation API with a built prompt.
 * On a 400 safety rejection, rewrites the prompt once and retries.
 * @param {string} builtPrompt - Already prefixed/suffixed prompt ready to send.
 * @param {string} originalPrompt - The raw variation, used as fallback revisedPrompt.
 * @returns {Promise<{ b64Json, imageUrl, revisedPrompt }>}
 */
const callImageAPI = async (builtPrompt, originalPrompt) => {
  const tryGenerate = async (p) => {
    const response = await openai.images.generate({
      model: 'gpt-image-1',
      prompt: p,
      n: 1,
      size: '1024x1024',
      quality: 'medium',
    });
    const imageData = response.data[0];
    if (!imageData) throw new Error('No image data returned from OpenAI.');
    return imageData;
  };

  let imageData;
  try {
    imageData = await tryGenerate(builtPrompt);
  } catch (err) {
    if (err instanceof OpenAI.APIError && err.status === 400) {
      const simplified = await simplifySafetyRetry(originalPrompt);
      const retryPrompt = WELLNESS_PREFIX + simplified + NO_TEXT_SUFFIX;
      imageData = await tryGenerate(retryPrompt);
    } else {
      throw err;
    }
  }

  return {
    b64Json: imageData.b64_json || null,
    imageUrl: imageData.url || null,
    revisedPrompt: imageData.revised_prompt || originalPrompt,
  };
};

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
    return await callImageAPI(
      WELLNESS_PREFIX + prompt.trim() + NO_TEXT_SUFFIX,
      prompt.trim()
    );
  } catch (err) {
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

const NO_TEXT_AND_SYMBOLIC_SUFFIX =
  ' No text or words in the image. Symbolic and metaphorical imagery only.';

/**
 * Use GPT to expand a user concept into 4 distinct image prompts,
 * each interpreting the concept from a different scene/composition/subject
 * while sharing a consistent artistic style.
 * @param {string} concept
 * @returns {Promise<string[]>} Array of 4 image prompts
 */
const expandConceptToPrompts = async (concept) => {
  const completion = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: `You are a creative director for an AI art therapy app.
Given a user's concept or emotional theme, generate exactly 4 distinct image prompts.
Each prompt must:
- Interpret the concept from a completely different angle (different scene, subject, and composition)
- Share the same artistic style: soft, painterly, ethereal, emotionally evocative
- Be vivid and specific enough for an image generation model
- Avoid any text, letters, or words in the described scene
Return ONLY a JSON array of 4 strings, no explanation. Example format: ["prompt one", "prompt two", "prompt three", "prompt four"]`,
      },
      {
        role: 'user',
        content: `Concept: "${concept.trim()}"`,
      },
    ],
    max_tokens: 600,
    temperature: 0.9,
    response_format: { type: 'json_object' },
  });

  const raw = completion.choices[0]?.message?.content?.trim() || '{}';
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error('Failed to parse prompt variations from GPT.');
  }

  // Accept either a top-level array or an object with any array value
  const prompts = Array.isArray(parsed)
    ? parsed
    : Object.values(parsed).find((v) => Array.isArray(v));

  if (!Array.isArray(prompts) || prompts.length < 4) {
    throw new Error('GPT did not return 4 prompt variations.');
  }

  return prompts.slice(0, 4).map((p) => String(p));
};

/**
 * Generate 4 images from a concept by first expanding it into 4 distinct prompts,
 * then generating one image per prompt in parallel.
 * @param {string} prompt
 * @returns {Promise<Array<{ b64Json, imageUrl, revisedPrompt }>>}
 */
const generateImages = async (prompt) => {
  if (!prompt || typeof prompt !== 'string') {
    throw new Error('A valid prompt string is required.');
  }

  const variations = await expandConceptToPrompts(prompt);

  const results = await Promise.all(
    variations.map((variation) =>
      callImageAPI(
        WELLNESS_PREFIX + variation + NO_TEXT_AND_SYMBOLIC_SUFFIX,
        variation
      )
    )
  );

  return results;
};

/**
 * Expand a user's emotional/reflective statement into a rich, symbolic image prompt.
 * @param {string} statement - The user's raw reflection text.
 * @returns {Promise<string>} An expanded artistic image prompt.
 */
const expandReflectionToPrompt = async (statement) => {
  const completion = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content:
          'You are an art director for a wellness app. Take the user\'s emotional statement and expand it into a rich, symbolic, non-literal image generation prompt. ' +
          'Use metaphorical and abstract imagery — no people unless absolutely essential, no text or words in the image. ' +
          'Be vivid and specific: describe lighting, color palette, atmosphere, and symbolic elements. ' +
          'Return only the expanded prompt, nothing else.',
      },
      { role: 'user', content: statement.trim() },
    ],
    max_tokens: 250,
    temperature: 0.85,
  });
  return completion.choices[0]?.message?.content?.trim() || statement.trim();
};

/**
 * Expand a reflection statement into an artistic prompt, then generate a single image.
 * @param {string} statement - The user's raw reflection text.
 * @returns {Promise<{ b64Json, imageUrl, revisedPrompt }>}
 */
const generateImageFromReflection = async (statement) => {
  if (!statement || typeof statement !== 'string') {
    throw new Error('A valid statement string is required.');
  }

  try {
    const expanded = await expandReflectionToPrompt(statement);
    return await callImageAPI(
      WELLNESS_PREFIX + expanded + NO_TEXT_SUFFIX,
      expanded
    );
  } catch (err) {
    if (err instanceof OpenAI.APIError) {
      throw new Error(`OpenAI API error (${err.status}): ${err.message}`);
    }
    throw err;
  }
};

module.exports = { generateImage, generateImages, generateInsights, generateImageFromReflection, expandReflectionToPrompt };
