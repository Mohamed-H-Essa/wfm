import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../app/themes/typography.dart';
import '../../../../shared/widgets/gradient_header.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../providers/standup_provider.dart';
import '../../data/models/task_form_data.dart';

class EveningSummaryScreen extends ConsumerStatefulWidget {
  final int? standupId; // If provided, we're viewing an existing standup
  
  const EveningSummaryScreen({super.key, this.standupId});

  @override
  ConsumerState<EveningSummaryScreen> createState() => _EveningSummaryScreenState();
}

class _EveningSummaryScreenState extends ConsumerState<EveningSummaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _blockerController = TextEditingController();
  int? _productivityRating;
  String? _blockerDescription;
  String _blockerPriority = 'MEDIUM';
  List<TaskFormData> _unplannedTasks = [];
  bool _isViewMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isViewMode = widget.standupId != null;
    if (_isViewMode && widget.standupId != null) {
      _loadExistingStandup();
    }
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _blockerController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingStandup() async {
    if (widget.standupId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final repository = ref.read(standupRepositoryProvider);
      final response = await repository.getById(widget.standupId!);
      
      if (response.success && response.data != null) {
        final data = response.data!;
        
        if (mounted) {
          setState(() {
            _summaryController.text = data['work_summary']?.toString() ?? '';
            _productivityRating = data['productivity_rating'] != null
                ? (data['productivity_rating'] is int
                    ? data['productivity_rating'] as int
                    : int.tryParse(data['productivity_rating'].toString()))
                : null;
            _blockerDescription = data['blocker_description']?.toString();
            _blockerController.text = _blockerDescription ?? '';
            _blockerPriority = data['blocker_priority']?.toString() ?? 'MEDIUM';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_isViewMode) return; // Don't submit in view mode
    if (!_formKey.currentState!.validate()) return;

    try {
      final repository = ref.read(standupRepositoryProvider);
      
      final unplannedTasksData = _unplannedTasks.where((task) => task.title != null && task.title!.isNotEmpty).map((task) {
        final taskMap = <String, dynamic>{
          'title': task.title ?? '',
        };
        
        if (task.selectedProject != null) {
          taskMap['project_id'] = task.selectedProject!.id;
        } else if (task.customProjectName != null && task.customProjectName!.isNotEmpty) {
          taskMap['project_id'] = 'other';
          taskMap['category'] = task.customProjectName;
        }
        
        if (task.estimatedHours != null) {
          taskMap['hours'] = task.estimatedHours;
        }
        
        return taskMap;
      }).toList();
      
      final response = await repository.submitEvening(
        workSummary: _summaryController.text.trim(),
        productivityRating: _productivityRating,
        blockerDescription: _blockerDescription?.trim().isEmpty == true ? null : _blockerDescription?.trim(),
        blockerPriority: _blockerDescription?.trim().isEmpty == true ? null : _blockerPriority,
        unplannedTasks: _unplannedTasks.isEmpty ? null : unplannedTasksData,
      );
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evening summary submitted successfully'),
              backgroundColor: IntraZeroColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to submit evening summary'),
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: IntraZeroColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: IntraZeroColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          GradientHeader(
            title: _isViewMode ? 'Evening Summary' : 'End Your Day',
            subtitle: DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
            icon: _isViewMode ? Icons.visibility : Icons.nightlight,
            gradient: IntraZeroColors.eveningGradient,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: GlassmorphismCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, color: IntraZeroColors.primaryGradient.colors.first),
                          const SizedBox(width: 10),
                          Text(
                            'How did your day go?',
                            style: IntraZeroTypography.label,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _summaryController,
                        readOnly: _isViewMode,
                        decoration: InputDecoration(
                          hintText: _isViewMode 
                              ? 'No summary provided'
                              : 'Describe what you accomplished today...',
                        ),
                        maxLines: 5,
                        validator: _isViewMode ? null : (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide a summary';
                          }
                          if (value.trim().length < 50) {
                            return 'Please provide a more detailed summary (minimum 50 characters)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Icon(Icons.star, color: IntraZeroColors.primaryGradient.colors.first),
                          const SizedBox(width: 10),
                          Text(
                            'Productivity Rating',
                            style: IntraZeroTypography.label,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          final rating = index + 1;
                          return GestureDetector(
                            onTap: _isViewMode ? null : () {
                              setState(() {
                                _productivityRating = rating;
                              });
                            },
                            child: Icon(
                              _productivityRating != null && rating <= _productivityRating!
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 40,
                              color: _productivityRating != null && rating <= _productivityRating!
                                  ? IntraZeroColors.warning
                                  : IntraZeroColors.borderMedium,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Icon(Icons.block, color: IntraZeroColors.primaryGradient.colors.first),
                          const SizedBox(width: 10),
                          Text(
                            'Any Blockers? (Optional)',
                            style: IntraZeroTypography.label,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _blockerController,
                        readOnly: _isViewMode,
                        decoration: InputDecoration(
                          hintText: _isViewMode 
                              ? 'No blockers reported'
                              : 'Describe any blockers you faced...',
                        ),
                        maxLines: 3,
                        onChanged: _isViewMode ? null : (value) {
                          setState(() {
                            _blockerDescription = value;
                          });
                        },
                      ),
                      if (_blockerDescription != null && _blockerDescription!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: IntraZeroColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: IntraZeroColors.warning.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.block, color: IntraZeroColors.warning, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Blocker',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: IntraZeroColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _blockerDescription!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                      if (!_isViewMode) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GradientButton(
                              text: 'Submit',
                              gradient: IntraZeroColors.eveningGradient,
                              icon: Icons.check,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
