// models/Inventory.js
const mongoose = require("mongoose");

const InventorySchema = new mongoose.Schema({
  sku: { type: String, required: true, index: true },
  name: { type: String, required: true },
  qty: { type: Number, required: true, default: 0 },
  uom: { type: String, required: true },   // đơn vị: EA, BOX...
  wh: { type: String, required: true },    // mã warehouse
  location: { type: String },              // vị trí kệ
  exp: { type: Date }                      // hạn dùng
}, { timestamps: true });

module.exports = mongoose.model("inventory", InventorySchema);
