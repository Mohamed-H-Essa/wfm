import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ForgotCheckinScreen extends ConsumerStatefulWidget {
  const ForgotCheckinScreen({super.key});

  @override
  ConsumerState<ForgotCheckinScreen> createState() => _ForgotCheckinScreenState();
}

class _ForgotCheckinScreenState extends ConsumerState<ForgotCheckinScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String _type = 'CHECK_IN';
  final _timeController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _timeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;

    try {
      final repository = AttendanceRepository(ref.read(apiClientProvider));
      final response = await repository.submitForgotCheckin(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        type: _type,
        reason: _reasonController.text.trim(),
      );
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request submitted successfully'),
              backgroundColor: IntraZeroColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to submit request'),
              backgroundColor: IntraZeroColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: IntraZeroColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Check In/Out'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: GlassmorphismCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    suffixIcon: const Icon(Icons.calendar_today),
                    hintText: _selectedDate == null
                        ? 'Select date'
                        : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                  ),
                  onTap: _selectDate,
                  validator: (value) {
                    if (_selectedDate == null) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'CHECK_IN', child: Text('Check In')),
                    DropdownMenuItem(value: 'CHECK_OUT', child: Text('Check Out')),
                    DropdownMenuItem(value: 'BOTH', child: Text('Both')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _type = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    labelText: 'Requested Time',
                    hintText: 'HH:mm (e.g., 09:00)',
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Explain why you forgot to check in/out',
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a reason';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                GradientButton(
                  text: 'Submit Request',
                  gradient: IntraZeroColors.primaryGradient,
                  icon: Icons.send,
                  isFullWidth: true,
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
