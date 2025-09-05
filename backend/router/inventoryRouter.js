const express = require('express');
const InventoryControlller = require('../controllers/inventoryController');
const authMiddleware = require('../middlewares/authMiddleware');
const router = express.Router();

// Lấy danh sách kho hàng
router.get('/getInventory', InventoryControlller.getInventory);
router.get('/getInventory/:sku', InventoryControlller.getInventoryBySku);
// Tạo mới kho hàng
router.post('/createInventory', authMiddleware.VerifyToken, InventoryControlller.createInventory);
// Cập nhật kho hàng
router.put('/updateInventory/:sku', authMiddleware.VerifyToken, InventoryControlller.updateInventory);
router.delete('/deleteInventory/:sku',authMiddleware.VerifyToken, InventoryControlller.deleteInventory);
router.get('/getAllQuantityInventory', InventoryControlller.getAllQuanlityInventory);//http://localhost:5000/api/inventory/getAllQuantityInventory
router.get('/getLowQuanlityItems', InventoryControlller.getLowQuanlityItems);//http://localhost:5000/api/inventory/getLowQuanlityItems
module.exports = router;