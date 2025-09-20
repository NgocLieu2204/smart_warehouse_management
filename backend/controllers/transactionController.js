const Transaction = require('../models/Transaction');
const inventory = require('../models/inventory');

const TransactionController = {
    async addTransaction(req, res) {
        try{
            const { sku, type, qty,wh,by,note } = req.body;

            // Create a new transaction
            const newTransaction = new Transaction({ sku, type, qty,wh,by,note });
            await newTransaction.save();

            //Update inventory based on transaction type
            let inventoryItem = await inventory.findOne({ sku });
            if (!inventoryItem) {
                return res.status(404).json({ message: "Inventory item not found" });
            }

            if(type === 'inbound'){
                inventoryItem.qty += qty;
            }
            else if(type === 'outbound'){   
                if(inventoryItem.qty < qty){
                    return res.status(400).json({ message: "Insufficient inventory for outbound transaction" });
                }
                inventoryItem.qty -= qty;
            } else {
                return res.status(400).json({ message: "Invalid transaction type" });
            }
            
            await inventoryItem.save();
            res.status(201).json({ message: "Transaction added successfully", transaction: newTransaction, updatedInventory: inventoryItem });
            
        }
        catch(error){
            res.status(500).json({ message: "Error processing transaction", error });
        }
    },
    async getTransaction(req,res) {
        try {
            const transactions = await Transaction.find().sort({ at: -1 }); // mới nhất trước
            res.json(transactions);
        } catch (err) {
            res.status(500).json({ message: err.message });
        }
    } 
    
}
module.exports = TransactionController;