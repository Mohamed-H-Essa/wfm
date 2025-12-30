import '../models/project_model.dart';

class TaskFormData {
  String? title;
  String? priority;
  double? estimatedHours;
  Project? selectedProject;
  String? customProjectName;

  TaskFormData({
    this.title,
    this.priority = 'MEDIUM',
    this.estimatedHours,
    this.selectedProject,
    this.customProjectName,
  });
}

