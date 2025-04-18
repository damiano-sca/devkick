import 'package:flutter/material.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/models/command.dart';
import 'package:devkick/core/services/command_service.dart';
import 'package:devkick/core/widgets/command_output_dialog.dart';
import 'package:devkick/features/home/presentation/widgets/add_command_dialog.dart';
import 'package:devkick/features/home/presentation/widgets/edit_command_dialog.dart';
import 'package:devkick/core/services/toast_service.dart';

class HomePage extends StatelessWidget {
  final Function(Command command)? onRunCommand;
  final GlobalKey<_CommandListViewState> commandListKey = GlobalKey<_CommandListViewState>();

  HomePage({
    super.key,
    this.onRunCommand,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command List'),
        centerTitle: true,
      ),
      body: CommandListView(
        key: commandListKey,
        onRunCommand: onRunCommand
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCommandDialog(context),
        tooltip: 'Add New Command',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddCommandDialog(BuildContext context) async {
    final result = await showDialog<Command>(
      context: context,
      builder: (context) => const AddCommandDialog(),
    );
    
    if (result != null && context.mounted) {
      // Save the new command
      final response = await CommandService.saveCommand(result);
      
      if (context.mounted) {
        if (response['success']) {
          ToastService.showSuccess(context, 'Command added successfully');
          
          // Refresh the command list using the global key
          commandListKey.currentState?.refreshCommands();
        } else {
          ToastService.showError(context, 'Failed to add command');
        }
      }
    }
  }

  Future<void> _executeCommand(BuildContext context, String command, {TerminalType terminalType = TerminalType.prompt}) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await CommandService.executeCommand(command, terminalType: terminalType);
      
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      // Show output dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => CommandOutputDialog(
            command: command,
            output: result.stdout.toString(),
            error: result.stderr.toString(),
            exitCode: result.exitCode,
            terminalType: terminalType,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      // Show error
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => CommandOutputDialog(
            command: command,
            output: '',
            error: e.toString(),
            exitCode: -1,
            terminalType: terminalType,
          ),
        );
      }
    }
  }
}

class CommandListView extends StatefulWidget {
  final Function(Command command)? onRunCommand;

  const CommandListView({
    super.key,
    this.onRunCommand,
  });

  @override
  State<CommandListView> createState() => _CommandListViewState();
}

class _CommandListViewState extends State<CommandListView> {
  List<Command> _commandItems = [];
  bool _isLoading = true;
  
  // Map of categories to their commands
  Map<String, List<Command>> _categorizedCommands = {};

  @override
  void initState() {
    super.initState();
    _loadCommands();
  }

  Future<void> _loadCommands() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize the service first
      await CommandService.init();
      final commands = await CommandService.getAllCommands();
      
      // Group commands by category
      final Map<String, List<Command>> grouped = {};
      for (final command in commands) {
        final category = command.category;
        if (!grouped.containsKey(category)) {
          grouped[category] = [];
        }
        grouped[category]!.add(command);
      }
      
      setState(() {
        _commandItems = commands;
        _categorizedCommands = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading commands: $e')),
        );
      }
    }
  }

  // Method to refresh the command list
  void refreshCommands() {
    _loadCommands();
  }

  Future<void> _editCommand(Command command) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditCommandDialog(command: command),
    );
    
    // Handle the result
    if (result != null && mounted) {
      switch (result['action']) {
        case 'edit':
          final newCommand = result['command'] as Command;
          final response = await CommandService.saveCommand(newCommand);
          
          if (mounted) {
            if (response['success']) {
              final updatedRoutines = response['updatedRoutines'] as int;
              final message = updatedRoutines > 0
                  ? 'Command updated successfully (updated in $updatedRoutines routines)'
                  : 'Command updated successfully';
                  
              ToastService.showSuccess(context, message);
              refreshCommands();
            } else {
              ToastService.showError(context, 'Failed to update command');
            }
          }
          break;
          
        case 'delete':
          await _deleteCommand(command);
          break;
      }
    }
  }

  Future<void> _deleteCommand(Command command) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Command'),
        content: Text('Are you sure you want to delete "${command.label}"?'),
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

    if (confirmed == true) {
      final response = await CommandService.deleteCommand(command.id);
      if (mounted) {
        if (response['success']) {
          final updatedRoutines = response['updatedRoutines'] as int;
          final message = updatedRoutines > 0
              ? 'Command deleted successfully (removed from $updatedRoutines routines)'
              : 'Command deleted successfully';
              
          ToastService.showSuccess(context, message);
          refreshCommands();
        } else {
          ToastService.showError(context, 'Failed to delete command');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_commandItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.terminal_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No commands added yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first command by clicking the + button',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Get sorted categories
    final categories = _categorizedCommands.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final commandsInCategory = _categorizedCommands[category]!;
        
        return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Category header
            Padding(
              padding: const EdgeInsets.only(
                left: 8, 
                top: 16, 
                bottom: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, 
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${commandsInCategory.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // List of commands in this category
            ...commandsInCategory.map((item) => CommandItemWidget(
              key: ValueKey(item.id),
              item: item,
              onRun: () {
                if (widget.onRunCommand != null) {
                  widget.onRunCommand!(item);
                } else {
                  _executeCommand(context, item.command, terminalType: item.terminalType);
                }
              },
              onEdit: () => _editCommand(item),
              onDelete: () => _deleteCommand(item),
            )),
            
            // Add divider except for the last category
            if (index < categories.length - 1)
              const Divider(height: 32),
          ],
        );
      },
    );
  }

  // Get an appropriate icon for a category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return Icons.star;
      case 'development':
        return Icons.code;
      case 'database':
        return Icons.storage;
      case 'testing':
        return Icons.science;
      case 'deployment':
        return Icons.rocket_launch;
      case 'utilities':
        return Icons.handyman;
      case 'system':
        return Icons.computer;
      case 'network':
        return Icons.wifi;
      case 'security':
        return Icons.security;
      case 'docker':
        return Icons.inventory_2;
      case 'git':
        return Icons.merge_type;
      case 'web':
        return Icons.web;
      case 'mobile':
        return Icons.phone_android;
      default:
        return Icons.category;
    }
  }

  Future<void> _executeCommand(BuildContext context, String command, {TerminalType terminalType = TerminalType.prompt}) async {
    final homePage = context.findAncestorWidgetOfExactType<HomePage>();
    if (homePage != null) {
      await homePage._executeCommand(
        context, 
        command,
        terminalType: terminalType,
      );
    }
  }
}

class CommandItemWidget extends StatelessWidget {
  final Command item;
  final VoidCallback onRun;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CommandItemWidget({
    super.key,
    required this.item,
    required this.onRun,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Command'),
            content: Text('Are you sure you want to delete "${item.label}"?'),
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
      },
      onDismissed: (direction) {
        onDelete();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
        child: InkWell(
          onTap: onRun,
          onLongPress: onEdit, // Long press to edit
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: Icon(
              item.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            title: Text(
              item.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              item.command,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Command',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete Command',
                  onPressed: onDelete,
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Run Command',
                  onPressed: onRun,
                ),
              ],
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
          ),
        ),
      ),
    );
  }
} 