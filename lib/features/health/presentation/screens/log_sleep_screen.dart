import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/sleep_log.dart';

class LogSleepScreen extends ConsumerStatefulWidget {
  const LogSleepScreen({super.key});

  @override
  ConsumerState<LogSleepScreen> createState() => _LogSleepScreenState();
}

class _LogSleepScreenState extends ConsumerState<LogSleepScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  DateTime? _sleepAt;
  DateTime? _wokeAt;
  int? _quality;
  bool _submitting = false;

  SleepLog? _editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is SleepLog && _editing == null) {
      _editing = args;
      _sleepAt = _editing!.sleepAt;
      _wokeAt = _editing!.wokeAt;
      _quality = _editing!.quality;
      _noteController.text = _editing!.note ?? '';
    }
    if (_sleepAt == null) {
      final now = DateTime.now();
      _sleepAt = DateTime(now.year, now.month, now.day, 23, 0);
      _wokeAt = DateTime(now.year, now.month, now.day, 7, 0);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool wake}) async {
    final initial = wake ? _wokeAt! : _sleepAt!;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (wake) {
        _wokeAt = combined;
      } else {
        _sleepAt = combined;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final sleepAt = _sleepAt!;
    final wokeAt = _wokeAt!;
    if (!wokeAt.isAfter(sleepAt)) {
      _showMessage('Wake time must be after bedtime.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      final repository = ref.read(sleepRepositoryProvider);
      if (_editing != null) {
        await repository.updateSleepLog(
          _editing!.id,
          sleepAt: sleepAt,
          wokeAt: wokeAt,
          quality: _quality,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
      } else {
        await repository.logSleep(
          sleepAt: sleepAt,
          wokeAt: wokeAt,
          quality: _quality,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(e.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing != null ? 'Edit sleep' : 'Log sleep')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateField(
                  label: 'Went to bed',
                  value: _sleepAt,
                  onTap: () => _pickDateTime(wake: false),
                ),
                const SizedBox(height: 16),
                _DateField(
                  label: 'Woke up',
                  value: _wokeAt,
                  onTap: () => _pickDateTime(wake: true),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<int?>(
                  initialValue: _quality,
                  decoration: const InputDecoration(labelText: 'Quality (optional)'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Not rated')),
                    for (var i = 1; i <= 5; i++)
                      DropdownMenuItem<int?>(value: i, child: Text('$i / 5')),
                  ],
                  onChanged: (value) => setState(() => _quality = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),
                AppPrimaryButton(
                  label: _editing != null ? 'Save Changes' : 'Log Sleep',
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

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Select'
        : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')} '
            '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.schedule),
        ),
        child: Text(text),
      ),
    );
  }
}
