// services/storageService.js
const { BlockBlobClient } = require('@azure/storage-blob');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const CONNECTION_STRING = process.env.AZURE_STORAGE_CONNECTION_STRING;
const ACCOUNT_NAME = process.env.AZURE_STORAGE_ACCOUNT_NAME || 'gmuteammergeconflicts';
const SAS_TOKEN = process.env.AZURE_STORAGE_SAS_TOKEN;
const CONTAINER_NAME = process.env.AZURE_STORAGE_CONTAINER_NAME || 'images';

// Container must be pre-created in Azure portal (private, no public access)
const initializeBlobStorage = async () => {
  console.log('✅ Azure Blob Storage ready');
};

/**
 * Upload a base64-encoded image to Azure Blob Storage and return a URL.
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

  // Construct a direct SAS URL for this blob and upload to it
  const blobSasUrl = `https://${ACCOUNT_NAME}.blob.core.windows.net/${CONTAINER_NAME}/${blobName}?${SAS_TOKEN}`;
  const blockBlobClient = new BlockBlobClient(blobSasUrl);

  await blockBlobClient.uploadData(buffer, {
    blobHTTPHeaders: { blobContentType: 'image/png' },
  });

  return blobSasUrl;
};

/**
 * Delete an image from Azure Blob Storage by its URL.
 * @param {string} imageUrl - The full URL of the image to delete.
 */
const deleteImage = async (imageUrl) => {
  try {
    // Strip any existing query string and re-attach the SAS token
    const blobPath = new URL(imageUrl).pathname;
    const blobSasUrl = `https://${ACCOUNT_NAME}.blob.core.windows.net${blobPath}?${SAS_TOKEN}`;
    await new BlockBlobClient(blobSasUrl).delete();
  } catch (err) {
    console.error('Warning: Failed to delete image from Azure:', err.message);
    // Non-fatal — we still want to remove the DB record
  }
};

module.exports = { initializeBlobStorage, uploadImage, deleteImage };
