const express = require('express');
const router = express.Router();
const TransactionController = require('../controllers/transactionController');
const authMiddleware = require('../middlewares/authMiddleware');
router.post('/addTransaction', authMiddleware.VerifyToken, TransactionController.addTransaction);

module.exports = router; 