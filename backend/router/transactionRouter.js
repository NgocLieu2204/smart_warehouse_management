const express = require('express');
const router = express.Router();
const TransactionController = require('../controllers/transactionController');

router.post('/addTransaction', TransactionController.addTransaction);

module.exports = router; 