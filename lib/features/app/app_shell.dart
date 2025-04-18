import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/models/command.dart';
import 'package:devkick/core/models/command_session.dart';
import 'package:devkick/core/services/command_service.dart';
import 'package:devkick/features/home/presentation/pages/home_page.dart';
import 'package:devkick/features/terminal/presentation/pages/terminals_page.dart';
import 'package:devkick/features/settings/presentation/pages/settings_page.dart';
import 'package:devkick/features/routines/presentation/pages/routines_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Index of selected destination in the navigation rail
  int _selectedIndex = 0;
  
  // List of active command sessions
  final List<CommandSession> _commandSessions = [];
  
  // UUID generator for session IDs
  final Uuid _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Create list of destinations for navigation rail
    final List<NavigationRailDestination> destinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.code_outlined),
        selectedIcon: Icon(Icons.code),
        label: Text('Commands'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.playlist_play_outlined),
        selectedIcon: Icon(Icons.playlist_play),
        label: Text('Routines'),
      ),
      // Add terminal destination
      NavigationRailDestination(
        icon: Badge(
          isLabelVisible: _commandSessions.isNotEmpty,
          label: Text(
            _commandSessions.length.toString(),
            style: const TextStyle(fontSize: 10),
          ),
          child: const Icon(Icons.terminal_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: _commandSessions.isNotEmpty,
          label: Text(
            _commandSessions.length.toString(),
            style: const TextStyle(fontSize: 10),
          ),
          child: const Icon(Icons.terminal),
        ),
        label: const Text('Terminals'),
      ),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: destinations,
            backgroundColor: theme.colorScheme.surface,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      Icons.terminal,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Settings',
                    onPressed: _openSettings,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Vertical Divider
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          // Main Content - Use IndexedStack to preserve widget state when switching tabs
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                // Keep these widgets alive by using the IndexedStack
                HomePage(
                  onRunCommand: _startCommandSession,
                ),
                RoutinesPage(
                  onRunCommand: _startCommandSession,
                ),
                TerminalsPage(
                  sessions: _commandSessions,
                  onTerminate: _terminateSession,
                  onSessionUpdated: _updateSession,
                  onRunCommand: _startCommandSession,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Open settings page
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  // Start a new command session
  void _startCommandSession(Command command) {
    // Check if a session for this command already exists
    final existingSessionIndex = _commandSessions.indexWhere(
      (session) => session.command.id == command.id && 
                   session.command.command == command.command &&
                   session.isRunning
    );
    
    if (existingSessionIndex >= 0) {
      // If a session already exists, just navigate to the terminals page
      setState(() {
        _selectedIndex = 2; // Terminals page index
      });
      return;
    }
    
    // Otherwise create a new session
    final sessionId = _uuid.v4();
    final session = CommandSession(
      id: sessionId,
      command: command,
    );
    
    setState(() {
      _commandSessions.add(session);
      _selectedIndex = 2; // Navigate to terminals page
    });
  }

  // Terminate a command session
  void _terminateSession(String sessionId) {
    final sessionIndex = _commandSessions.indexWhere((s) => s.id == sessionId);
    
    if (sessionIndex != -1) {
      CommandService.killProcess(sessionId);
      
      setState(() {
        _commandSessions.removeAt(sessionIndex);
      });
    }
  }
  
  // Update a command session in our list
  void _updateSession(CommandSession updatedSession) {
    final sessionIndex = _commandSessions.indexWhere((s) => s.id == updatedSession.id);
    
    if (sessionIndex != -1) {
      setState(() {
        _commandSessions[sessionIndex] = updatedSession;
      });
    }
  }
} 