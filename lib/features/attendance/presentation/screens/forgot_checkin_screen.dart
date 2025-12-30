import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/models/forgot_checkin_settings_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'forgot_requests_screen.dart';

class ForgotCheckinScreen extends ConsumerStatefulWidget {
  const ForgotCheckinScreen({super.key});

  @override
  ConsumerState<ForgotCheckinScreen> createState() => _ForgotCheckinScreenState();
}

class _ForgotCheckinScreenState extends ConsumerState<ForgotCheckinScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String _type = 'CHECK_IN';
  TimeOfDay? _selectedCheckInTime;
  TimeOfDay? _selectedCheckOutTime;
  final _reasonController = TextEditingController();
  final _jiraProofController = TextEditingController();
  
  ForgotCheckinSettingsModel? _settings;
  bool _loadingSettings = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _reasonController.dispose();
    _jiraProofController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    try {
      final repository = AttendanceRepository(ref.read(apiClientProvider));
      final response = await repository.getForgotCheckinSettings();
      
      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            _settings = response.data;
          }
          _loadingSettings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSettings = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: ${e.toString()}'),
            backgroundColor: IntraZeroColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    if (_settings == null) return;
    
    final restrictions = _settings!.restrictions;
    final earliest = restrictions.earliestAllowedDate;
    final latest = restrictions.latestAllowedDate;
    final helpText = _settings!.helpText.maxDaysBack ?? 'Select date for forgot check-in/out';
    
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: earliest,
      lastDate: latest,
      helpText: helpText,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Reset times when date changes
        _selectedCheckInTime = null;
        _selectedCheckOutTime = null;
      });
    }
  }

  Future<void> _selectCheckInTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedCheckInTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: IntraZeroColors.primaryGradient.colors.first,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: IntraZeroColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedCheckInTime = picked;
      });
    }
  }

  Future<void> _selectCheckOutTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedCheckOutTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: IntraZeroColors.primaryGradient.colors.first,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: IntraZeroColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedCheckOutTime = picked;
      });
    }
  }

  bool _validateBeforeSubmit() {
    if (_settings == null) return false;
    
    final userStatus = _settings!.userStatus;
    if (!userStatus.canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monthly limit reached. Wait for next month.'),
          backgroundColor: IntraZeroColors.danger,
        ),
      );
      return false;
    }
    
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: IntraZeroColors.warning,
        ),
      );
      return false;
    }
    
    // Validate date restrictions
    final restrictions = _settings!.restrictions;
    if (_selectedDate!.isBefore(restrictions.earliestAllowedDate) ||
        _selectedDate!.isAfter(restrictions.latestAllowedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_settings!.helpText.maxDaysBack ?? 'Date is outside allowed range'),
          backgroundColor: IntraZeroColors.warning,
        ),
      );
      return false;
    }
    
    // Validate same week deadline if enabled
    if (restrictions.deadlineInfo != null) {
      final deadline = restrictions.deadlineInfo!;
      if (_selectedDate!.isBefore(deadline.weekStart) ||
          _selectedDate!.isAfter(deadline.weekEnd)) {
        // Format dates for better error message
        final weekStartFormatted = DateFormat('EEE, MMM d').format(deadline.weekStart);
        final weekEndFormatted = DateFormat('EEE, MMM d').format(deadline.weekEnd);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selected date is outside the allowed working week.\n'
              'Allowed range: $weekStartFormatted to $weekEndFormatted\n'
              'Note: Working days are Sunday to Thursday',
            ),
            backgroundColor: IntraZeroColors.warning,
            duration: const Duration(seconds: 5),
          ),
        );
        return false;
      }
    }
    
    // Validate times based on type
    if (_type == 'CHECK_IN' || _type == 'BOTH') {
      if (_selectedCheckInTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select check-in time'),
            backgroundColor: IntraZeroColors.warning,
          ),
        );
        return false;
      }
    }
    
    if (_type == 'CHECK_OUT' || _type == 'BOTH') {
      if (_selectedCheckOutTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select check-out time'),
            backgroundColor: IntraZeroColors.warning,
          ),
        );
        return false;
      }
    }
    
    // Validate Jira proof if required
    if (_settings!.settings.requireJiraProof) {
      if (_jiraProofController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jira proof is required'),
            backgroundColor: IntraZeroColors.warning,
          ),
        );
        return false;
      }
    }
    
    return true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateBeforeSubmit()) return;
    
    setState(() {
      _submitting = true;
    });

    try {
      final repository = AttendanceRepository(ref.read(apiClientProvider));
      
      // Format times as HH:mm:ss
      String? checkInTimeString;
      String? checkOutTimeString;
      
      if (_selectedCheckInTime != null) {
        checkInTimeString = '${_selectedCheckInTime!.hour.toString().padLeft(2, '0')}:${_selectedCheckInTime!.minute.toString().padLeft(2, '0')}:00';
      }
      if (_selectedCheckOutTime != null) {
        checkOutTimeString = '${_selectedCheckOutTime!.hour.toString().padLeft(2, '0')}:${_selectedCheckOutTime!.minute.toString().padLeft(2, '0')}:00';
      }
      
      final response = await repository.submitForgotCheckin(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        type: _type,
        reason: _reasonController.text.trim(),
        requestedCheckInTime: checkInTimeString,
        requestedCheckOutTime: checkOutTimeString,
        jiraProof: _settings!.settings.requireJiraProof 
            ? _jiraProofController.text.trim() 
            : null,
      );
      
      if (response.success) {
        final data = response.data;
        final autoApproved = data?['auto_approved'] == true;
        final message = data?['message']?.toString() ?? 
            (autoApproved ? 'Request auto-approved!' : 'Request submitted for approval');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: IntraZeroColors.success,
            ),
          );
          
          // Refresh settings to update monthly count
          await _loadSettings();
          
          // Navigate back
          Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _buildUserStatusCard() {
    if (_settings == null) return const SizedBox.shrink();
    
    final userStatus = _settings!.userStatus;
    final helpText = _settings!.helpText;
    
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: userStatus.canSubmit 
                    ? IntraZeroColors.success 
                    : IntraZeroColors.danger,
              ),
              const SizedBox(width: 8),
              const Text(
                'Monthly Request Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${userStatus.remainingRequests} of ${userStatus.monthlyLimit} remaining',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: userStatus.canSubmit 
                  ? IntraZeroColors.success 
                  : IntraZeroColors.danger,
            ),
          ),
          if (helpText.monthlyLimit != null) ...[
            const SizedBox(height: 8),
            Text(
              helpText.monthlyLimit!,
              style: TextStyle(
                fontSize: 12,
                color: IntraZeroColors.textSecondary,
              ),
            ),
          ],
          if (!userStatus.canSubmit) ...[
            const SizedBox(height: 8),
            Text(
              'Monthly limit reached. Wait for next month.',
              style: TextStyle(
                fontSize: 12,
                color: IntraZeroColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeadlineWarning() {
    if (_settings == null) return const SizedBox.shrink();
    
    final deadlineInfo = _settings!.restrictions.deadlineInfo;
    if (deadlineInfo == null) return const SizedBox.shrink();
    
    // Format dates for display
    final weekStartFormatted = DateFormat('EEE, MMM d').format(deadlineInfo.weekStart);
    final weekEndFormatted = DateFormat('EEE, MMM d').format(deadlineInfo.weekEnd);
    
    // Check if the message mentions "Sunday to Saturday" and clarify it's working days
    String displayMessage = deadlineInfo.message;
    if (displayMessage.toLowerCase().contains('sunday to saturday') || 
        displayMessage.toLowerCase().contains('same week')) {
      displayMessage = 'Requests must be submitted within the same working week (Sunday to Thursday). '
          'Deadline: $weekStartFormatted to $weekEndFormatted';
    } else {
      // If message doesn't mention calendar week, just add the date range
      displayMessage = '${deadlineInfo.message}\nDeadline: $weekStartFormatted to $weekEndFormatted';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: IntraZeroColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: IntraZeroColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning, color: IntraZeroColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: IntraZeroColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Note: Working days are Sunday to Thursday',
                  style: TextStyle(
                    fontSize: 11,
                    color: IntraZeroColors.warning.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Check In/Out'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotRequestsScreen()),
              );
            },
            tooltip: 'View All Requests',
          ),
        ],
      ),
      body: _loadingSettings
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load settings'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User status card
                      _buildUserStatusCard(),
                      const SizedBox(height: 16),
                      
                      // Deadline warning
                      _buildDeadlineWarning(),
                      
                      // Form
                      GlassmorphismCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Date picker
                              TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Date *',
                                  suffixIcon: const Icon(Icons.calendar_today),
                                  hintText: _selectedDate == null
                                      ? 'Select date'
                                      : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                                  helperText: _settings!.helpText.maxDaysBack,
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
                              
                              // Type selector
                              DropdownButtonFormField<String>(
                                value: _type,
                                decoration: const InputDecoration(labelText: 'Type *'),
                                items: const [
                                  DropdownMenuItem(value: 'CHECK_IN', child: Text('Check In')),
                                  DropdownMenuItem(value: 'CHECK_OUT', child: Text('Check Out')),
                                  DropdownMenuItem(value: 'BOTH', child: Text('Both')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _type = value!;
                                    // Reset times when type changes
                                    if (_type == 'CHECK_OUT') {
                                      _selectedCheckInTime = null;
                                    }
                                    if (_type == 'CHECK_IN') {
                                      _selectedCheckOutTime = null;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              // Check-in time (if CHECK_IN or BOTH)
                              if (_type == 'CHECK_IN' || _type == 'BOTH') ...[
                                TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Check-in Time *',
                                    hintText: _selectedCheckInTime == null
                                        ? 'Select check-in time'
                                        : _selectedCheckInTime!.format(context),
                                    suffixIcon: const Icon(Icons.access_time),
                                  ),
                                  onTap: _selectCheckInTime,
                                  validator: (value) {
                                    if (_selectedCheckInTime == null) {
                                      return 'Please select check-in time';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                              
                              // Check-out time (if CHECK_OUT or BOTH)
                              if (_type == 'CHECK_OUT' || _type == 'BOTH') ...[
                                TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Check-out Time *',
                                    hintText: _selectedCheckOutTime == null
                                        ? 'Select check-out time'
                                        : _selectedCheckOutTime!.format(context),
                                    suffixIcon: const Icon(Icons.access_time),
                                  ),
                                  onTap: _selectCheckOutTime,
                                  validator: (value) {
                                    if (_selectedCheckOutTime == null) {
                                      return 'Please select check-out time';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                              
                              // Reason
                              TextFormField(
                                controller: _reasonController,
                                decoration: const InputDecoration(
                                  labelText: 'Reason *',
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
                              const SizedBox(height: 20),
                              
                              // Jira proof (if required)
                              if (_settings!.settings.requireJiraProof) ...[
                                TextFormField(
                                  controller: _jiraProofController,
                                  decoration: InputDecoration(
                                    labelText: 'Jira Worklog Proof *',
                                    hintText: 'Enter Jira ticket IDs (e.g., JIRA-123, JIRA-456)',
                                    helperText: _settings!.helpText.jiraProof,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Jira proof is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                              
                              // Auto-approve info
                              if (_settings!.helpText.autoApprove != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: IntraZeroColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, 
                                          color: IntraZeroColors.info, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _settings!.helpText.autoApprove!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: IntraZeroColors.info,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                              
                              // Submit button
                              GradientButton(
                                text: 'Submit Request',
                                gradient: IntraZeroColors.primaryGradient,
                                icon: Icons.send,
                                isFullWidth: true,
                                onPressed: _settings!.userStatus.canSubmit && !_submitting
                                    ? _submit
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
