const express = require('express');
const { register, login, me, updatePreferences } = require('../controllers/auth.controller');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.get('/me', requireAuth, me);
router.put('/preferences', requireAuth, updatePreferences);

module.exports = router;
