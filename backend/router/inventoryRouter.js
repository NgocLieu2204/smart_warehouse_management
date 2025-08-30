const express = require('express');
const InventoryControlller = require('../controllers/inventoryController');

const router = express.Router();

// Lấy danh sách kho hàng
router.get('/getInventory', InventoryControlller.getInventory);
router.get('/getInventory/:sku', InventoryControlller.getInventoryBySku);
// Tạo mới kho hàng
router.post('/createInventory', InventoryControlller.createInventory);
// Cập nhật kho hàng
router.put('/updateInventory/:sku', InventoryControlller.updateInventory);
router.delete('/deleteInventory/:sku', InventoryControlller.deleteInventory);
router.get('/getAllQuantityInventory', InventoryControlller.getAllQuanlityInventory);//http://localhost:5000/api/inventory/getAllQuantityInventory
router.get('/getLowQuanlityItems', InventoryControlller.getLowQuanlityItems);//http://localhost:5000/api/inventory/getLowQuanlityItems
module.exports = router;