import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/todo.dart';

class AddEditTodoScreen extends ConsumerStatefulWidget {
  const AddEditTodoScreen({super.key});

  @override
  ConsumerState<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends ConsumerState<AddEditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Todo? _editing;
  DateTime? _dueDate;
  TodoPriority _priority = TodoPriority.medium;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Todo && _editing == null) {
      _editing = args;
      _titleController.text = _editing!.title;
      _descriptionController.text = _editing!.description ?? '';
      _dueDate = _editing!.dueDate;
      _priority = _editing!.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final existing = _dueDate;
    final combined = existing == null
        ? DateTime(date.year, date.month, date.day, 23, 59)
        : DateTime(
            date.year,
            date.month,
            date.day,
            existing.hour,
            existing.minute,
          );
    setState(() => _dueDate = combined);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final repository = ref.read(todoRepositoryProvider);
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    try {
      if (_editing != null) {
        await repository.updateTodo(
          _editing!.id,
          title: title,
          description: description,
          dueDate: _dueDate,
          priority: _priority,
        );
      } else {
        await repository.createTodo(
          title: title,
          description: description,
          dueDate: _dueDate,
          priority: _priority,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing != null ? 'Edit todo' : 'New todo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return 'Title is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TodoPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: TodoPriority.values
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _priority = value);
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDueDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due date',
                      prefixIcon: Icon(Icons.event_outlined),
                      suffixIcon: Icon(Icons.chevron_right),
                    ),
                    child: Text(
                      _dueDate == null
                          ? 'No due date'
                          : '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                if (_dueDate != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _dueDate = null),
                      child: const Text('Clear due date'),
                    ),
                  ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: _editing != null ? 'Save Changes' : 'Create Todo',
                  loading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
