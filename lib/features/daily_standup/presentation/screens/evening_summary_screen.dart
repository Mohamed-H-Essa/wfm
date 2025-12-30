import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../app/themes/typography.dart';
import '../../../../shared/widgets/gradient_header.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/project_selector.dart';
import '../providers/standup_provider.dart';
import '../../data/models/project_model.dart';
import '../../data/models/task_form_data.dart';

class EveningSummaryScreen extends ConsumerStatefulWidget {
  const EveningSummaryScreen({super.key});

  @override
  ConsumerState<EveningSummaryScreen> createState() => _EveningSummaryScreenState();
}

class _EveningSummaryScreenState extends ConsumerState<EveningSummaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  int? _productivityRating;
  String? _blockerDescription;
  String _blockerPriority = 'MEDIUM';
  List<TaskFormData> _unplannedTasks = [];

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final repository = ref.read(standupRepositoryProvider);
      
      final unplannedTasksData = _unplannedTasks.map((task) {
        final taskMap = <String, dynamic>{
          'title': task.title,
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
    final projectsAsync = ref.watch(standupProjectsProvider);
    
    return Scaffold(
      backgroundColor: IntraZeroColors.background,
      body: Column(
        children: [
          GradientHeader(
            title: 'End Your Day',
            subtitle: DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
            icon: Icons.nightlight,
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
                        decoration: const InputDecoration(
                          hintText: 'Describe what you accomplished today...',
                        ),
                        maxLines: 5,
                        validator: (value) {
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
                            onTap: () {
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
                        decoration: const InputDecoration(
                          hintText: 'Describe any blockers you faced...',
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          setState(() {
                            _blockerDescription = value;
                          });
                        },
                      ),
                      const SizedBox(height: 30),
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
