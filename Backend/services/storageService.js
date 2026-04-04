// services/storageService.js
const { BlobServiceClient } = require('@azure/storage-blob');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const CONNECTION_STRING = process.env.AZURE_STORAGE_CONNECTION_STRING;
const ACCOUNT_NAME = process.env.AZURE_STORAGE_ACCOUNT_NAME || 'gmuteammergeconflicts';
const SAS_TOKEN = process.env.AZURE_STORAGE_SAS_TOKEN;
const CONTAINER_NAME = process.env.AZURE_STORAGE_CONTAINER_NAME || 'images';

/**
 * Upload a base64-encoded image to Azure Blob Storage and return a public URL.
 * @param {string} b64Data - Base64-encoded image data (no data URI prefix).
 * @param {string} userId - The user's ID, used for folder organization.
 * @returns {Promise<string>} - The URL of the uploaded image.
 */
const uploadImage = async (b64Data, userId) => {
  if (!b64Data) {
    throw new Error('No image data provided for upload.');
  }

  const buffer = Buffer.from(b64Data, 'base64');
  const blobName = `${userId}/${uuidv4()}.png`;

  const blobServiceClient = BlobServiceClient.fromConnectionString(CONNECTION_STRING);
  const containerClient = blobServiceClient.getContainerClient(CONTAINER_NAME);

  await containerClient.createIfNotExists({ access: 'blob' });

  const blockBlobClient = containerClient.getBlockBlobClient(blobName);
  await blockBlobClient.uploadData(buffer, {
    blobHTTPHeaders: { blobContentType: 'image/png' },
  });

  // Append SAS token so the URL is accessible even if anonymous access is restricted
  const imageUrl = `https://${ACCOUNT_NAME}.blob.core.windows.net/${CONTAINER_NAME}/${blobName}?${SAS_TOKEN}`;
  return imageUrl;
};

/**
 * Delete an image from Azure Blob Storage by its URL.
 * @param {string} imageUrl - The full URL of the image to delete.
 */
const deleteImage = async (imageUrl) => {
  try {
    const url = new URL(imageUrl);
    // Path is /{container}/{userId}/{filename}
    const blobName = url.pathname.split('/').slice(2).join('/');

    const blobServiceClient = BlobServiceClient.fromConnectionString(CONNECTION_STRING);
    const containerClient = blobServiceClient.getContainerClient(CONTAINER_NAME);
    await containerClient.getBlockBlobClient(blobName).delete();
  } catch (err) {
    console.error('Warning: Failed to delete image from Azure:', err.message);
    // Non-fatal — we still want to remove the DB record
  }
};

module.exports = { uploadImage, deleteImage };
