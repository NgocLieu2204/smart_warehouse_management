const express = require('express');
const InventoryControlller = require('../controllers/inventoryController');

const router = express.Router();

// Lấy danh sách kho hàng
router.get('/getInventory', InventoryControlller.getInventory);
module.exports = router;