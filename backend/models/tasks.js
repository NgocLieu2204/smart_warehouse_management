// models/Task.js
const mongoose = require("mongoose");

const TaskSchema = new mongoose.Schema({
  type: { type: String, enum: ["cycle_count", "putaway", "pick"], required: true },
  status: { type: String, enum: ["open", "done"], default: "open" },
  priority: { type: String, enum: ["low", "normal", "high"], default: "normal" },
  payload: {
    sku: { type: String, required: true },
    wh: { type: String, required: true }
  },
  created_at: { type: Date, default: Date.now },
  due_at: { type: Date },
  assignee: { type: String }   // ai được giao task
}, { timestamps: true });

module.exports = mongoose.model("Task", TaskSchema);
