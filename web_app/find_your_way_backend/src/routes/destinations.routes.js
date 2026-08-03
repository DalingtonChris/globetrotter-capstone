const express = require('express');
const { list, categories, getById, recommendations } = require('../controllers/destinations.controller');
const { optionalAuth } = require('../middleware/auth');

const router = express.Router();

router.get('/destinations', list);
router.get('/destinations/categories', categories);
router.get('/destinations/:id', getById);
router.get('/recommendations', optionalAuth, recommendations);

module.exports = router;
