import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_warehouse_manager/models/task_model.dart';
import 'package:smart_warehouse_manager/services/task_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task; // Nếu task != null -> Chế độ Sửa, ngược lại là Thêm

  const AddEditTaskScreen({Key? key, this.task}) : super(key: key);

  @override
  _AddEditTaskScreenState createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskService = TaskService();

  // Controllers cho các trường văn bản
  late TextEditingController _skuController;
  late TextEditingController _whController;
  late TextEditingController _assigneeController;

  // Biến lưu trữ giá trị cho các Dropdown và Date
  String? _selectedType;
  String? _selectedStatus;
  String? _selectedPriority;
  DateTime? _selectedDueDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final isEditMode = widget.task != null;

    // Khởi tạo giá trị ban đầu cho form
    _skuController = TextEditingController(text: isEditMode ? widget.task!.payload.sku : '');
    _whController = TextEditingController(text: isEditMode ? widget.task!.payload.wh : '');
    _assigneeController = TextEditingController(text: isEditMode ? widget.task!.assignee : '');
    _selectedType = isEditMode ? widget.task!.type : null;
    _selectedStatus = isEditMode ? widget.task!.status : null;
    _selectedPriority = isEditMode ? widget.task!.priority : null;
    _selectedDueDate = isEditMode ? widget.task!.dueAt : null;
  }

  @override
  void dispose() {
    _skuController.dispose();
    _whController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDueDate) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final payload = Payload(sku: _skuController.text, wh: _whController.text);
        
        if (widget.task == null) { // Chế độ Thêm mới
          final newTask = Task(
            // id và createdAt sẽ được tạo bởi backend
            id: '', 
            createdAt: DateTime.now(),
            type: _selectedType!,
            status: _selectedStatus!,
            priority: _selectedPriority!,
            payload: payload,
            dueAt: _selectedDueDate,
            assignee: _assigneeController.text.isNotEmpty ? _assigneeController.text : null,
          );
          await _taskService.createTask(newTask);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo công việc thành công!')));
        } else { // Chế độ Cập nhật
           final updatedTask = Task(
            id: widget.task!.id,
            createdAt: widget.task!.createdAt, // Giữ nguyên ngày tạo
            type: _selectedType!,
            status: _selectedStatus!,
            priority: _selectedPriority!,
            payload: payload,
            dueAt: _selectedDueDate,
            assignee: _assigneeController.text.isNotEmpty ? _assigneeController.text : null,
          );
          await _taskService.updateTask(widget.task!.id, updatedTask);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật công việc thành công!')));
        }
        
        Navigator.of(context).pop(true); // Trả về true để báo hiệu cần làm mới danh sách

      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      } finally {
        if (mounted) {
           setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _submitForm,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildDropdown(_selectedType, ['putaway', 'cycle_count', 'pick'], 'Type', (val) => setState(() => _selectedType = val)),
                  const SizedBox(height: 16),
                  _buildDropdown(_selectedStatus, ['open', 'done'], 'Status', (val) => setState(() => _selectedStatus = val)),
                  const SizedBox(height: 16),
                  _buildDropdown(_selectedPriority, ['low', 'normal', 'high'], 'Priority', (val) => setState(() => _selectedPriority = val)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(labelText: 'SKU', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Vui lòng nhập SKU' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _whController,
                    decoration: const InputDecoration(labelText: 'Warehouse (WH)', border: OutlineInputBorder()),
                     validator: (value) => value!.isEmpty ? 'Vui lòng nhập Warehouse' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _assigneeController,
                    decoration: const InputDecoration(labelText: 'Assignee (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                   ListTile(
                    title: Text('Due Date: ${_selectedDueDate == null ? 'Not Set' : DateFormat.yMd().format(_selectedDueDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey.shade400)
                    ),
                  ),
                ],
              ),
            ),
    );
  }

   Widget _buildDropdown(String? value, List<String> items, String label, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Vui lòng chọn $label' : null,
    );
  }
}