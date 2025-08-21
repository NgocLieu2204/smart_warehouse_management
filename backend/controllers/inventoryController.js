// controllers/inventoryController.js
const inventory = require('../models/inventory');
const InventoryController = {
    async getInventory(req , res) {
        try {
            const Inventory = await inventory.find();
            res.status(200).json(Inventory);
            console.log(Inventory);
        } catch (error) {
            res.status(500).json({ message: "Error fetching inventory", error });
        }
    },

   
    // async getInventoryBySku(req, res) {
    //     const { sku } = req.params;
    //     try {
    //         const inventoryItem = await Inventory.findOne({ sku });
    //         if (!inventoryItem) {
    //             return res.status(404).json({ message: "Inventory item not found" });
    //         }
    //         res.status(200).json(inventoryItem);
    //     } catch (error) {
    //         res.status(500).json({ message: "Error fetching inventory item", error });
    //     }
    // }
}

module.exports = InventoryController;
