// models/Transaction.js
const mongoose = require("mongoose");

const TransactionSchema = new mongoose.Schema({
  sku: { type: String, required: true },
  type: { type: String, enum: ["inbound", "outbound", "adjustment"], required: true },
  qty: { type: Number, required: true },
  wh: { type: String, required: true },
  at: { type: Date, default: Date.now },    // thời điểm nhập xuất
  by: { type: String },                     // user thao tác
  note: { type: String }
}, { timestamps: true });

module.exports = mongoose.model("Transaction", TransactionSchema);
