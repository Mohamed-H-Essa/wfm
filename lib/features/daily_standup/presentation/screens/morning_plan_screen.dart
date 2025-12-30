import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../app/themes/typography.dart';
import '../../../../shared/widgets/gradient_header.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/project_selector.dart';
import '../../data/models/project_model.dart';
import '../../data/models/task_form_data.dart';
import '../providers/standup_provider.dart';
import '../../data/repositories/standup_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/models/api_response.dart';

class MorningPlanScreen extends ConsumerStatefulWidget {
  final int? standupId; // If provided, we're editing an existing standup
  
  const MorningPlanScreen({super.key, this.standupId});

  @override
  ConsumerState<MorningPlanScreen> createState() => _MorningPlanScreenState();
}

class _MorningPlanScreenState extends ConsumerState<MorningPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalsController = TextEditingController();
  List<TaskFormData> _tasks = [];
  List<Project> _projects = [];
  String _workType = 'OFFICE';
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.standupId != null;
    _loadProjects().then((_) {
      // Load existing standup after projects are loaded (for edit mode)
      if (_isEditMode && widget.standupId != null) {
        _loadExistingStandup();
      }
    });
    if (!_isEditMode) {
      _tasks.add(TaskFormData());
    }
  }
  
  Future<void> _loadExistingStandup() async {
    if (widget.standupId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final repository = StandupRepository(ref.read(apiClientProvider));
      final response = await repository.getById(widget.standupId!);
      
      if (response.success && response.data != null) {
        final data = response.data!;
        
        // Pre-fill form with existing data
        if (mounted) {
          setState(() {
            _goalsController.text = data['today_goals']?.toString() ?? '';
            _workType = data['work_type']?.toString() ?? 'OFFICE';
            
            // Load existing tasks
            if (data['tasks'] != null && data['tasks'] is Map) {
              final tasksData = data['tasks'] as Map<String, dynamic>;
              if (tasksData['items'] != null && tasksData['items'] is List) {
                final items = tasksData['items'] as List<dynamic>;
                _tasks = items.map((item) {
                  final taskMap = item as Map<String, dynamic>;
                  return TaskFormData(
                    title: taskMap['title']?.toString() ?? '',
                    priority: taskMap['priority']?.toString(),
                    estimatedHours: taskMap['estimated_hours'] != null 
                        ? (taskMap['estimated_hours'] is num 
                            ? (taskMap['estimated_hours'] as num).toDouble()
                            : double.tryParse(taskMap['estimated_hours'].toString()))
                        : null,
                    selectedProject: taskMap['project_id'] != null && _projects.isNotEmpty
                        ? _projects.firstWhere(
                            (p) => p.id == (taskMap['project_id'] is int 
                                ? taskMap['project_id'] 
                                : int.tryParse(taskMap['project_id'].toString())),
                            orElse: () => _projects.first,
                          )
                        : null,
                    customProjectName: taskMap['category']?.toString(),
                  );
                }).toList();
              }
            }
            
            if (_tasks.isEmpty) {
              _tasks.add(TaskFormData());
            }
            
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

  @override
  void dispose() {
    _goalsController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    final projectsAsync = ref.watch(standupProjectsProvider);
    
    // Wait for projects to load
    await projectsAsync.when(
      data: (projects) {
        if (mounted) {
          setState(() {
            _projects = projects;
          });
        }
      },
      loading: () {},
      error: (_, __) {
        if (mounted) {
          setState(() {
            _projects = [];
          });
        }
      },
    );
  }

  void _addTask() {
    setState(() {
      _tasks.add(TaskFormData());
    });
  }

  void _removeTask(int index) {
    if (_tasks.length > 1) {
      setState(() {
        _tasks.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final repository = ref.read(standupRepositoryProvider);
      
      final tasksData = _tasks.map((task) {
        final taskMap = <String, dynamic>{
          'title': task.title,
          'priority': task.priority ?? 'MEDIUM',
        };
        
        if (task.selectedProject != null) {
          taskMap['project_id'] = task.selectedProject!.id;
        } else if (task.customProjectName != null && task.customProjectName!.isNotEmpty) {
          taskMap['project_id'] = 'other';
          taskMap['category'] = task.customProjectName;
        }
        
        if (task.estimatedHours != null) {
          taskMap['estimated_hours'] = task.estimatedHours;
        }
        
        return taskMap;
      }).toList();
      
      ApiResponse<Map<String, dynamic>> response;
      
      if (_isEditMode && widget.standupId != null) {
        // Update existing morning plan
        response = await repository.updateMorning(
          standupId: widget.standupId!,
          todayGoals: _goalsController.text.trim().isEmpty ? null : _goalsController.text.trim(),
          workType: _workType,
          tasks: tasksData,
        );
      } else {
        // Submit new morning plan
        response = await repository.submitMorning(
          todayGoals: _goalsController.text.trim().isEmpty ? null : _goalsController.text.trim(),
          workType: _workType,
          tasks: tasksData,
        );
      }
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode 
                  ? 'Morning plan updated successfully'
                  : 'Morning plan submitted successfully'),
              backgroundColor: IntraZeroColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to ${_isEditMode ? 'update' : 'submit'} morning plan'),
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
            title: _isEditMode ? 'Edit Morning Plan' : 'Start Your Day',
            subtitle: DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
            icon: _isEditMode ? Icons.edit : Icons.wb_sunny,
            gradient: IntraZeroColors.morningGradient,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _workType == 'WFH' ? 'Working from Home' : 
                _workType == 'LEAVE' ? 'On Leave' : 'At Office',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
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
                          Icon(Icons.track_changes, color: IntraZeroColors.primaryGradient.colors.first),
                          const SizedBox(width: 10),
                          Text(
                            "What's your main goal for today?",
                            style: IntraZeroTypography.label,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _goalsController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Complete the payment integration module',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your goal for today';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Icon(Icons.list, color: IntraZeroColors.primaryGradient.colors.first),
                          const SizedBox(width: 10),
                          Text(
                            'What tasks will you work on today?',
                            style: IntraZeroTypography.label,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_tasks.length, (index) {
                        return _buildTaskItem(index);
                      }),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _addTask,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: IntraZeroColors.borderMedium,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle, color: IntraZeroColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'Add Task',
                                style: TextStyle(color: IntraZeroColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GradientButton(
                            text: _isEditMode ? 'Update' : 'Submit',
                            gradient: IntraZeroColors.primaryGradient,
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

  Widget _buildTaskItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IntraZeroColors.surfaceLight,
        border: Border.all(color: IntraZeroColors.borderLight, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Task Title',
              hintText: 'What do you need to do?',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter task title';
              }
              return null;
            },
            onChanged: (value) {
              _tasks[index].title = value;
            },
          ),
          const SizedBox(height: 12),
          ProjectSelector(
            projects: _projects,
            selectedProject: _tasks[index].selectedProject,
            customProjectName: _tasks[index].customProjectName,
            onChanged: (project, customName) {
              setState(() {
                _tasks[index].selectedProject = project;
                _tasks[index].customProjectName = customName;
              });
            },
          ),
          if (_tasks.length > 1) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: IntraZeroColors.danger),
                onPressed: () => _removeTask(index),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

