// config/tableStorage.js
const { TableServiceClient, TableClient } = require('@azure/data-tables');
require('dotenv').config();

const CONNECTION_STRING = process.env.AZURE_STORAGE_CONNECTION_STRING;

const USERS_TABLE = 'users';
const IMAGES_TABLE = 'images';

const getUsersTable = () => TableClient.fromConnectionString(CONNECTION_STRING, USERS_TABLE);
const getImagesTable = () => TableClient.fromConnectionString(CONNECTION_STRING, IMAGES_TABLE);

const initializeTables = async () => {
  const serviceClient = TableServiceClient.fromConnectionString(CONNECTION_STRING);
  await serviceClient.createTable(USERS_TABLE).catch(() => {});
  await serviceClient.createTable(IMAGES_TABLE).catch(() => {});
  console.log('✅ Azure Table Storage tables ready');
};

module.exports = { getUsersTable, getImagesTable, initializeTables };
