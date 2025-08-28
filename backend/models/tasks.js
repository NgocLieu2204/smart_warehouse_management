const mongoose = require('mongoose');

// Schema con cho trường "payload"
const payloadSchema = new mongoose.Schema({
  sku: {
    type: String,
    required: true
  },
  wh: {
    type: String,
    required: true
  }
}, { _id: false }); // _id: false để không tạo _id cho sub-document

const taskSchema = new mongoose.Schema({
  type: {
    type: String,
    required: true,
    enum: ['putaway', 'cycle_count', 'pick']
  },
  status: {
    type: String,
    required: true,
    enum: ['open', 'done']
  },
  priority: {
    type: String,
    required: true,
    enum: ['low', 'normal', 'high']
  },
  payload: {
    type: payloadSchema,
    required: true
  },
  due_at: {
    type: Date,
    default: null
  },
  assignee: {
    type: String,
    default: null
  }
}, {
  // Tự động thêm `createdAt` và `updatedAt`
  // Tuy nhiên, dữ liệu của bạn có `created_at`, nên chúng ta sẽ dùng timestamps: true
  // và Mongoose sẽ tự quản lý.
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' }
});

const Task = mongoose.model('Task', taskSchema);

module.exports = Task;