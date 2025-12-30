import 'package:flutter/material.dart';
import '../../app/themes/colors.dart';
import '../../features/daily_standup/data/models/project_model.dart';

/// Project Selector Widget - Matching Standup Design with "Other" Option
class ProjectSelector extends StatefulWidget {
  final List<Project> projects;
  final Function(Project? project, String? customName) onChanged;
  final Project? selectedProject;
  final String? customProjectName;

  const ProjectSelector({
    super.key,
    required this.projects,
    required this.onChanged,
    this.selectedProject,
    this.customProjectName,
  });

  @override
  State<ProjectSelector> createState() => _ProjectSelectorState();
}

class _ProjectSelectorState extends State<ProjectSelector> {
  bool _showCustomInput = false;
  final TextEditingController _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showCustomInput = widget.selectedProject == null && 
                       widget.customProjectName != null;
    _customController.text = widget.customProjectName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_showCustomInput) {
      return _buildCustomInput();
    }
    return _buildDropdown();
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: IntraZeroColors.borderLight, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<Project?>(
        value: widget.selectedProject,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: InputBorder.none,
        ),
        items: [
          ...widget.projects.map((project) => DropdownMenuItem(
            value: project,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse(project.color.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(project.title),
              ],
            ),
          )),
          const DropdownMenuItem<Project?>(
            value: null,
            child: Row(
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 8),
                Text('✏️ Other (Custom)...'),
              ],
            ),
          ),
        ],
        onChanged: (Project? project) {
          if (project == null) {
            setState(() {
              _showCustomInput = true;
            });
            widget.onChanged(null, null);
          } else {
            widget.onChanged(project, null);
          }
        },
      ),
    );
  }

  Widget _buildCustomInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _customController,
            decoration: InputDecoration(
              labelText: 'Custom Project Name',
              prefixIcon: const Icon(Icons.edit),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: IntraZeroColors.borderLight, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: IntraZeroColors.primaryGradient.colors.first,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              widget.onChanged(null, value);
            },
            autofocus: true,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: IntraZeroColors.borderLight),
            borderRadius: BorderRadius.circular(8),
            color: IntraZeroColors.surfaceLight,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 18),
            color: IntraZeroColors.textSecondary,
            onPressed: () {
              setState(() {
                _showCustomInput = false;
                _customController.clear();
              });
              widget.onChanged(null, null);
            },
            tooltip: 'Back to project list',
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }
}

