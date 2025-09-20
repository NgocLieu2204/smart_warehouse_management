const express = require('express');
const router = express.Router();
const TransactionController = require('../controllers/transactionController');
const authMiddleware = require('../middlewares/authMiddleware');
router.post('/addTransaction', authMiddleware.VerifyToken, TransactionController.addTransaction);
router.get('/getTransaction',TransactionController.getTransaction);
module.exports = router; 