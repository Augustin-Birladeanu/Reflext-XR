// services/storageService.js
const { S3Client, PutObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'us-east-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
  // Optional: for S3-compatible services (Cloudflare R2, MinIO, etc.)
  ...(process.env.S3_ENDPOINT && { endpoint: process.env.S3_ENDPOINT }),
});

const BUCKET_NAME = process.env.S3_BUCKET_NAME || 'inscape-images';
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';

/**
 * Upload a base64-encoded image to S3 and return a permanent public URL.
 * @param {string} b64Data - Base64-encoded image data (no data URI prefix).
 * @param {string} userId - The user's ID, used for folder organization.
 * @returns {Promise<string>} - The permanent public URL of the uploaded image.
 */
const uploadImage = async (b64Data, userId) => {
  if (!b64Data) {
    throw new Error('No image data provided for upload.');
  }

  const buffer = Buffer.from(b64Data, 'base64');
  const key = `images/${userId}/${uuidv4()}.png`;

  const command = new PutObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
    Body: buffer,
    ContentType: 'image/png',
    // For public read access. Remove if using signed URLs.
  });

  await s3Client.send(command);

  // Construct the permanent public URL
  const endpoint = process.env.S3_ENDPOINT;
  let imageUrl;

  if (endpoint) {
    // S3-compatible endpoint (Cloudflare R2, MinIO, etc.)
    imageUrl = `${endpoint}/${BUCKET_NAME}/${key}`;
  } else {
    // Standard AWS S3
    imageUrl = `https://${BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com/${key}`;
  }

  return imageUrl;
};

/**
 * Delete an image from S3 by its full URL.
 * @param {string} imageUrl - The full URL of the image to delete.
 */
const deleteImage = async (imageUrl) => {
  try {
    // Extract the key from the URL
    const url = new URL(imageUrl);
    // Key is everything after the bucket name in the path
    const key = url.pathname.replace(`/${BUCKET_NAME}/`, '').replace(/^\//, '');

    const command = new DeleteObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
    });

    await s3Client.send(command);
  } catch (err) {
    console.error('Warning: Failed to delete image from S3:', err.message);
    // Non-fatal — we still want to remove the DB record
  }
};

module.exports = { uploadImage, deleteImage };
