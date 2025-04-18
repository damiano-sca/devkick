import 'package:flutter/material.dart';
import 'package:devkick/core/models/command.dart';
import 'package:devkick/core/models/command_session.dart';
import 'package:devkick/features/terminal/presentation/widgets/terminal_container.dart';

class TerminalsPage extends StatelessWidget {
  final List<CommandSession> sessions;
  final Function(String) onTerminate;
  final Function(CommandSession) onSessionUpdated;
  final Function(Command) onRunCommand;

  const TerminalsPage({
    super.key,
    required this.sessions,
    required this.onTerminate,
    required this.onSessionUpdated,
    required this.onRunCommand,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop_circle),
            tooltip: 'Terminate All Sessions',
            onPressed: sessions.isEmpty 
                ? null 
                : () => _showTerminateAllDialog(context),
          ),
        ],
      ),
      body: TerminalContainer(
        sessions: sessions,
        onTerminate: onTerminate,
        onSessionUpdated: onSessionUpdated,
        onAddSession: onRunCommand,
      ),
    );
  }

  void _showTerminateAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate All Sessions'),
        content: const Text('Are you sure you want to terminate all active terminal sessions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _terminateAllSessions();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Terminate All'),
          ),
        ],
      ),
    );
  }

  void _terminateAllSessions() {
    // Create a copy to avoid issues with modifying the list during iteration
    final sessionsToTerminate = List<String>.from(
      sessions.where((s) => s.isRunning).map((s) => s.id)
    );
    
    for (final sessionId in sessionsToTerminate) {
      onTerminate(sessionId);
    }
  }
} 