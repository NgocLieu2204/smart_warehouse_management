const Task = require('../models/tasks');

// @desc    Lấy tất cả tasks
// @route   GET /api/tasks
// @access  Public
const getAllTasks = async (req, res) => {
  try {
    const tasks = await Task.find({});
    res.status(200).json(tasks);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi khi lấy danh sách công việc', error: error.message });
  }
};

// @desc    Tạo một task mới
// @route   POST /api/tasks
// @access  Public
const createTask = async (req, res) => {
  try {
    const { type, status, priority, payload, due_at, assignee } = req.body;

    // Kiểm tra các trường bắt buộc
    if (!type || !status || !priority || !payload) {
        return res.status(400).json({ message: 'Vui lòng nhập các trường bắt buộc: type, status, priority, payload' });
    }
     if (!payload.sku || !payload.wh) {
        return res.status(400).json({ message: 'Payload phải chứa sku và wh' });
    }


    const newTask = new Task({
      type,
      status,
      priority,
      payload,
      due_at,
      assignee
    });

    const savedTask = await newTask.save();
    res.status(201).json(savedTask);
  } catch (error) {
    // Xử lý lỗi validation từ Mongoose
    if (error.name === 'ValidationError') {
      return res.status(400).json({ message: 'Dữ liệu không hợp lệ', error: error.message });
    }
    res.status(500).json({ message: 'Lỗi khi tạo công việc mới', error: error.message });
  }
};

// @desc    Cập nhật một task
// @route   PUT /api/tasks/:id
// @access  Public
const updateTask = async (req, res) => {
  try {
    const { id } = req.params;
    const updatedData = req.body;

    const updatedTask = await Task.findByIdAndUpdate(id, updatedData, { new: true, runValidators: true });

    if (!updatedTask) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    res.status(200).json(updatedTask);
  } catch (error) {
     if (error.name === 'ValidationError') {
      return res.status(400).json({ message: 'Dữ liệu cập nhật không hợp lệ', error: error.message });
    }
    res.status(500).json({ message: 'Lỗi khi cập nhật công việc', error: error.message });
  }
};

// @desc    Xóa một task
// @route   DELETE /api/tasks/:id
// @access  Public
const deleteTask = async (req, res) => {
  try {
    const { id } = req.params;
    const deletedTask = await Task.findByIdAndDelete(id);

    if (!deletedTask) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    res.status(200).json({ message: 'Công việc đã được xóa thành công' });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi khi xóa công việc', error: error.message });
  }
};


module.exports = {
  getAllTasks,
  createTask,
  updateTask,
  deleteTask,
};