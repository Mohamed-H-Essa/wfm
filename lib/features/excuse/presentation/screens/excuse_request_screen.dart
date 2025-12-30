import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../data/repositories/excuse_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final excuseRequestProvider = StateNotifierProvider<ExcuseRequestNotifier, ExcuseRequestState>((ref) {
  return ExcuseRequestNotifier(ref.watch(apiClientProvider));
});

class ExcuseRequestState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  ExcuseRequestState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ExcuseRequestState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return ExcuseRequestState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ExcuseRequestNotifier extends StateNotifier<ExcuseRequestState> {
  final ApiClient apiClient;
  late final ExcuseRepository excuseRepository;

  ExcuseRequestNotifier(this.apiClient) : super(ExcuseRequestState()) {
    excuseRepository = ExcuseRepository(apiClient);
  }

  Future<void> submitRequest({
    required String date,
    required String type,
    required String reason,
    String? fromTime,
    String? toTime,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await excuseRepository.submitRequest(
        date: date,
        type: type,
        reason: reason,
        fromTime: fromTime,
        toTime: toTime,
      );
      if (response.success) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class ExcuseRequestScreen extends ConsumerStatefulWidget {
  const ExcuseRequestScreen({super.key});

  @override
  ConsumerState<ExcuseRequestScreen> createState() => _ExcuseRequestScreenState();
}

class _ExcuseRequestScreenState extends ConsumerState<ExcuseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _selectedType;
  DateTime? _selectedDate;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;

  final List<String> _types = [
    'Late Arrival',
    'Early Departure',
    'Absence',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestState = ref.watch(excuseRequestProvider);

    if (requestState.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excuse request submitted successfully')),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Excuse Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassmorphismCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: IntraZeroColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: IntraZeroColors.surface,
                      ),
                      items: _types.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a type';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassmorphismCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: IntraZeroColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: IntraZeroColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: IntraZeroColors.borderLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                                  : 'Select date',
                              style: TextStyle(
                                color: _selectedDate != null
                                    ? IntraZeroColors.textPrimary
                                    : IntraZeroColors.textSecondary,
                              ),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedType == 'Late Arrival' || _selectedType == 'Early Departure') ...[
                const SizedBox(height: 20),
                GlassmorphismCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: IntraZeroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectFromTime(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: IntraZeroColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: IntraZeroColors.borderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fromTime != null
                                    ? _fromTime!.format(context)
                                    : 'Select from time',
                                style: TextStyle(
                                  color: _fromTime != null
                                      ? IntraZeroColors.textPrimary
                                      : IntraZeroColors.textSecondary,
                                ),
                              ),
                              const Icon(Icons.access_time),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassmorphismCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'To Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: IntraZeroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectToTime(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: IntraZeroColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: IntraZeroColors.borderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _toTime != null
                                    ? _toTime!.format(context)
                                    : 'Select to time',
                                style: TextStyle(
                                  color: _toTime != null
                                      ? IntraZeroColors.textPrimary
                                      : IntraZeroColors.textSecondary,
                                ),
                              ),
                              const Icon(Icons.access_time),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              GlassmorphismCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: IntraZeroColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: IntraZeroColors.surface,
                        hintText: 'Enter reason',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a reason';
                        }
                        if (value.length < 10) {
                          return 'Reason must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (requestState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    requestState.error!,
                    style: const TextStyle(color: IntraZeroColors.danger),
                  ),
                ),
              GradientButton(
                text: requestState.isLoading ? 'Submitting...' : 'Submit Request',
                onPressed: requestState.isLoading ? null : _submitRequest,
                gradient: IntraZeroColors.primaryGradient,
                icon: requestState.isLoading ? null : Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectFromTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _fromTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _fromTime = picked;
      });
    }
  }

  Future<void> _selectToTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _toTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _toTime = picked;
      });
    }
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedType == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    ref.read(excuseRequestProvider.notifier).submitRequest(
          date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
          type: _selectedType!,
          reason: _reasonController.text,
          fromTime: _fromTime != null
              ? '${_fromTime!.hour.toString().padLeft(2, '0')}:${_fromTime!.minute.toString().padLeft(2, '0')}'
              : null,
          toTime: _toTime != null
              ? '${_toTime!.hour.toString().padLeft(2, '0')}:${_toTime!.minute.toString().padLeft(2, '0')}'
              : null,
        );
  }
}

