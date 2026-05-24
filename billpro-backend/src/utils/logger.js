const winston = require('winston');
const path = require('path');
const util = require('util');

const logDir = process.env.LOG_DIR || './logs';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({
      filename: path.join(logDir, 'error.log'),
      level: 'error',
      maxsize: 10 * 1024 * 1024, // 10MB
      maxFiles: 5,
    }),
    new winston.transports.File({
      filename: path.join(logDir, 'combined.log'),
      maxsize: 10 * 1024 * 1024,
      maxFiles: 10,
    }),
  ],
});

// Always add Console transport so logs are captured by Render, PM2, Docker, or other cloud log aggregators
logger.add(new winston.transports.Console({
  format: winston.format.combine(
    winston.format.colorize(),
    winston.format.printf(({ timestamp, level, message, ...meta }) => {
      const metaStr = Object.keys(meta).length 
        ? `\n${util.inspect(meta, { depth: 5, colors: process.env.NODE_ENV !== 'production', compact: false })}` 
        : '';
      return `${timestamp} [${level}]: ${message} ${metaStr}`;
    })
  ),
}));

module.exports = logger;
