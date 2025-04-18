import 'package:flutter/material.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/models/routine.dart';
import 'package:devkick/core/services/routine_service.dart';
import 'package:devkick/features/routines/presentation/widgets/add_routine_dialog.dart';
import 'package:devkick/features/routines/presentation/widgets/edit_routine_dialog.dart';
import 'package:devkick/core/models/command.dart';
import 'package:devkick/core/models/process_result.dart';
import 'package:devkick/core/services/toast_service.dart';

class RoutinesPage extends StatefulWidget {
  final Function(Command command)? onRunCommand;

  const RoutinesPage({
    super.key,
    this.onRunCommand,
  });

  @override
  State<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage> {
  List<Routine> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Force refresh to ensure we get the latest routines with updated commands
      final routines = await RoutineService.getRoutines(forceRefresh: true);
      setState(() {
        _routines = routines;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Error loading routines: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddRoutineDialog() async {
    final result = await showDialog<Routine>(
      context: context,
      builder: (context) => const AddRoutineDialog(),
    );

    if (result != null && mounted) {
      final success = await RoutineService.addRoutine(result);
      
      if (mounted) {
        if (success) {
          ToastService.showSuccess(context, 'Routine added successfully');
          _loadRoutines();
        } else {
          ToastService.showError(context, 'Failed to add routine');
        }
      }
    }
  }

  Future<void> _showEditRoutineDialog(Routine routine) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditRoutineDialog(routine: routine),
    );

    if (result != null && mounted) {
      switch (result['action']) {
        case 'edit':
          final updatedRoutine = result['routine'] as Routine;
          final success = await RoutineService.updateRoutine(routine.id, updatedRoutine);
          
          if (mounted) {
            if (success) {
              ToastService.showSuccess(context, 'Routine updated successfully');
              _loadRoutines();
            } else {
              ToastService.showError(context, 'Failed to update routine');
            }
          }
          break;
          
        case 'delete':
          await _deleteRoutine(routine);
          break;
      }
    }
  }

  Future<void> _deleteRoutine(Routine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text('Are you sure you want to delete "${routine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await RoutineService.deleteRoutine(routine.id);
      if (mounted) {
        if (success) {
          ToastService.showSuccess(context, 'Routine deleted successfully');
          _loadRoutines();
        } else {
          ToastService.showError(context, 'Failed to delete routine');
        }
      }
    }
  }

  Future<void> _executeRoutine(Routine routine) async {
    if (widget.onRunCommand == null) {
      // If onRunCommand is not provided, use the old execution method
      setState(() {
        _isLoading = true;
      });

      try {
        final results = await RoutineService.executeRoutine(routine);

        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        // Show results in a dialog
        _showResultsDialog(routine, results);
        ToastService.showSuccess(context, 'Routine executed successfully');
      } catch (error) {
        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        // Show error dialog
        _showErrorDialog(error.toString());
        ToastService.showError(context, 'Error executing routine');
      }
    } else {
      // Use the navigation rail method to run commands
      List<Command> commands = RoutineService.getRoutineCommands(routine);
      for (var command in commands) {
        widget.onRunCommand!(command);
      }

      ToastService.showInfo(
        context, 
        'Started commands from routine: ${routine.name}'
      );
    }
  }

  // Show results dialog
  void _showResultsDialog(Routine routine, List<Map<Command, ProcessResult>> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Results for ${routine.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final resultMap = results[index];
              final command = resultMap.keys.first;
              final result = resultMap[command]!;
              
              return ExpansionTile(
                title: Text(command.label),
                subtitle: Text('Exit code: ${result.exitCode}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (result.stdout.toString().isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Output:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                width: double.infinity,
                                child: Text(result.stdout.toString()),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        if (result.stderr.toString().isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Error:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                width: double.infinity,
                                child: Text(result.stderr.toString(), style: const TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show error dialog
  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routines'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routines.isEmpty
              ? _buildEmptyState(theme)
              : _buildRoutineList(theme),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoutineDialog,
        tooltip: 'Add New Routine',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.playlist_add_check,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No routines added yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first routine by clicking the + button',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: _routines.length,
      itemBuilder: (context, index) {
        final routine = _routines[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(
                  routine.icon,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                title: Text(
                  routine.name,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  routine.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Routine',
                      onPressed: () => _showEditRoutineDialog(routine),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete Routine',
                      onPressed: () => _deleteRoutine(routine),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      tooltip: 'Run Routine',
                      onPressed: () => _executeRoutine(routine),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commands (${routine.commands.length}):',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    if (routine.commands.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('No commands added to this routine'),
                      )
                    else
                      ...routine.commands.map((command) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(command.icon, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                command.label,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      )),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        routine.runInParallel 
                            ? 'Run in parallel' 
                            : 'Run sequentially',
                      ),
                      avatar: Icon(
                        routine.runInParallel 
                            ? Icons.compare_arrows 
                            : Icons.arrow_downward,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 