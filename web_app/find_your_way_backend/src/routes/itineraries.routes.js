const express = require('express');
const { list, getById, create, remove } = require('../controllers/itineraries.controller');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);

router.get('/', list);
router.get('/:id', getById);
router.post('/', create);
router.delete('/:id', remove);

module.exports = router;
