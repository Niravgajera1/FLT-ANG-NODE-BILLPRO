const Redis = require('ioredis');
const logger = require('../utils/logger');

let redisClient = {};

const connectRedis = async () => {
  logger.info('Redis connection mocked');
  return redisClient;
};

const getRedis = () => {
  return redisClient;
};

// ─── In-Memory Store for Mocked Redis ──────────────────────────────────────────
const mockStore = {};

const setOTP = async (key, otp, expirySeconds = 600) => {
  logger.info(`Mock setOTP called for key: ${key}`);
  mockStore[`otp:${key}`] = otp;
};

const getOTP = async (key) => {
  logger.info(`Mock getOTP called for key: ${key}`);
  return mockStore[`otp:${key}`] || null;
};

const deleteOTP = async (key) => {
  logger.info(`Mock deleteOTP called for key: ${key}`);
  delete mockStore[`otp:${key}`];
};

const setCache = async (key, value, ttlSeconds = 300) => {
  logger.info(`Mock setCache called for key: ${key}`);
  mockStore[key] = JSON.stringify(value);
};

const getCache = async (key) => {
  logger.info(`Mock getCache called for key: ${key}`);
  const val = mockStore[key];
  return val ? JSON.parse(val) : null;
};

const deleteCache = async (key) => {
  logger.info(`Mock deleteCache called for key: ${key}`);
  delete mockStore[key];
};

const blacklistToken = async (token, expiresInSeconds) => {
  logger.info(`Mock blacklistToken called`);
};

const isTokenBlacklisted = async (token) => {
  logger.info(`Mock isTokenBlacklisted called`);
  return false;
};

module.exports = {
  connectRedis,
  getRedis,
  setOTP, getOTP, deleteOTP,
  setCache, getCache, deleteCache,
  blacklistToken, isTokenBlacklisted,
};
