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

   
    async getInventoryBySku(req, res) {
        const { sku } = req.params;
        try {
            const inventoryItem = await inventory.findOne({ sku });
            if (!inventoryItem) {
                return res.status(404).json({ message: "Inventory item not found" });
            }
            res.status(200).json(inventoryItem);
        } catch (error) {
            res.status(500).json({ message: "Error fetching inventory item", error });
        }
    },
    async createInventory(req, res) {
        const { sku, name, qty, uom, wh, location, imageUrl, exp } = req.body;
        try {
            const newInventory = new inventory({ sku, name, qty, uom, wh, location, imageUrl, exp });
            await newInventory.save();
            res.status(201).json(newInventory);
        } catch (error) {
            res.status(500).json({ message: "Error creating inventory item", error });
        }
    },
    async updateInventory(req, res) {
        const { sku } = req.params;
        const { name, qty, uom, wh, location, imageUrl, exp } = req.body;
        try {
            const updatedInventory = await inventory.findOneAndUpdate(
                { sku },
                { name, qty, uom, wh, location, imageUrl, exp },
                { new: true }
            );
            if (!updatedInventory) {
                return res.status(404).json({ message: "Inventory item not found" });
            }
            res.status(200).json(updatedInventory);
        } catch (error) {
            res.status(500).json({ message: "Error updating inventory item", error });
        }
    },
    async deleteInventory(req, res) {
        const { sku } = req.params;
        try {
            const deletedInventory = await inventory.findOneAndDelete({ sku });
            if (!deletedInventory) {
                return res.status(404).json({ message: "Inventory item not found" });
            }
            res.status(200).json({ message: "Inventory item deleted successfully" });
        } catch (error) {
            res.status(500).json({ message: "Error deleting inventory item", error });
        }
    },
    async getAllQuanlityInventory(req, res) {
        try {
            const totalQuantity = await inventory.aggregate([
                {
                    $group: {
                        _id: null,
                        totalQty: { $sum: "$qty" }
                    }
                }
            ]);
            console.log("Aggregate result:", totalQuantity);
            res.status(200).json({ totalQuantity: totalQuantity[0]?.totalQty || 0 });
        } catch (error) {
            res.status(500).json({ message: "Error calculating total quantity", error });
        }
    },
    async getLowQuanlityItems(req, res) {
        try {
            const lowQuantityItems = await inventory.countDocuments({ qty: { $lt: 10 } });    
            res.status(200).json(lowQuantityItems);
        } catch (error) {
            res.status(500).json({ message: "Error fetching low quantity items", error });  
        }
    }
};

module.exports = InventoryController;
