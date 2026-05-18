const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { ALLOWED_MIME_TYPES } = require('../config/constants');

// Store in memory (files will be uploaded to S3/cloud storage in service layer)
const storage = multer.memoryStorage();

const fileFilter = (allowedTypes) => (req, file, cb) => {
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`File type ${file.mimetype} not allowed`), false);
  }
};

// For invoice attachments (PDF, JPG, PNG — max 5MB)
const attachmentUpload = multer({
  storage,
  limits: { fileSize: (parseInt(process.env.MAX_ATTACHMENT_SIZE_MB) || 5) * 1024 * 1024 },
  fileFilter: fileFilter(ALLOWED_MIME_TYPES.DOCUMENTS),
});

// For company logo (JPG, PNG — max 2MB)
const logoUpload = multer({
  storage,
  limits: { fileSize: (parseInt(process.env.MAX_LOGO_SIZE_MB) || 2) * 1024 * 1024 },
  fileFilter: fileFilter(ALLOWED_MIME_TYPES.IMAGES),
});

// For bulk imports (XLSX, CSV — max 10MB)
const importUpload = multer({
  storage,
  limits: { fileSize: (parseInt(process.env.MAX_IMPORT_SIZE_MB) || 10) * 1024 * 1024 },
  fileFilter: fileFilter(ALLOWED_MIME_TYPES.IMPORTS),
});

// For item images (stored locally in uploads/Item — max 2MB)
const itemStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = path.join(__dirname, '../../uploads/Item');
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'item-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const itemUpload = multer({
  storage: itemStorage,
  limits: { fileSize: 2 * 1024 * 1024 },
  fileFilter: fileFilter(ALLOWED_MIME_TYPES.IMAGES),
});

module.exports = { attachmentUpload, logoUpload, importUpload, itemUpload };
