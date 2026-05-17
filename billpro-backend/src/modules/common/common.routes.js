const express = require('express');
const router = express.Router();
const ctrl = require('./common.controller');

// Public route to fetch all common static config
router.get('/', ctrl.getCommonData);

// Dynamic route to fetch specific common static config (e.g. states, businessTypes, businessCategories)
router.get('/:type', ctrl.getCommonData);

module.exports = router;
