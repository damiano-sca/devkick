import 'package:flutter/material.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/models/routine.dart';
import 'package:devkick/core/models/command.dart';
import 'package:devkick/core/services/command_service.dart';
import 'package:devkick/core/services/toast_service.dart';

class EditRoutineDialog extends StatefulWidget {
  final Routine routine;

  const EditRoutineDialog({super.key, required this.routine});

  @override
  State<EditRoutineDialog> createState() => _EditRoutineDialogState();
}

class _EditRoutineDialogState extends State<EditRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  
  late bool _runInParallel;
  late List<Command> _selectedCommands;
  List<Command> _availableCommands = [];
  bool _isLoadingCommands = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _descriptionController = TextEditingController(text: widget.routine.description);
    _runInParallel = widget.routine.runInParallel;
    
    // Initialize with existing commands from the routine
    _selectedCommands = List.from(widget.routine.commands);
    
    _loadCommands();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCommands() async {
    setState(() {
      _isLoadingCommands = true;
    });

    try {
      // Use the CommandService to get the actual saved commands
      final commands = await CommandService.getAllCommands();
      
      // Keep the currently selected commands
      final selectedCommandIds = _selectedCommands.map((c) => c.command).toSet();
      
      setState(() {
        _availableCommands = commands;
        // Make sure we don't lose the current selections
        if (_selectedCommands.isEmpty) {
          // If no commands were initially selected, try to find matches
          _selectedCommands = commands
              .where((command) => selectedCommandIds.contains(command.command))
              .toList();
        }
        _isLoadingCommands = false;
      });
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Error loading commands: $e');
        setState(() {
          _isLoadingCommands = false;
        });
      }
    }
  }

  void _toggleCommand(Command command) {
    setState(() {
      if (_selectedCommands.contains(command)) {
        _selectedCommands.remove(command);
      } else {
        _selectedCommands.add(command);
      }
    });
  }

  void _updateRoutine() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCommands.isEmpty) {
        ToastService.showError(context, 'Please select at least one command');
        return;
      }

      final updatedRoutine = widget.routine.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        commands: _selectedCommands,
        runInParallel: _runInParallel,
      );

      Navigator.of(context).pop({
        'action': 'edit',
        'routine': updatedRoutine,
      });
    } else {
      ToastService.showError(context, 'Please fix the validation errors');
    }
  }

  void _deleteRoutine() {
    Navigator.of(context).pop({
      'action': 'delete',
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Routine',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: 'Delete Routine',
                      onPressed: _deleteRoutine,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Routine Name',
                    hintText: 'Enter name for this routine',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter description for this routine',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Run commands in parallel',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Switch(
                      value: _runInParallel,
                      onChanged: (value) {
                        setState(() {
                          _runInParallel = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Commands',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _isLoadingCommands
                    ? const Center(child: CircularProgressIndicator())
                    : _availableCommands.isEmpty
                        ? Center(
                            child: Text(
                              'No commands available. Add some commands first.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          )
                        : Expanded(
                            child: ListView.builder(
                              itemCount: _availableCommands.length,
                              itemBuilder: (context, index) {
                                final command = _availableCommands[index];
                                final isSelected = _selectedCommands.contains(command);
                                
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (value) => _toggleCommand(command),
                                  title: Text(command.label),
                                  subtitle: Text(
                                    command.command,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  secondary: Icon(command.icon),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  dense: false, // Make the tile less compact
                                  tileColor: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.2) : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              },
                            ),
                          ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _updateRoutine,
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 