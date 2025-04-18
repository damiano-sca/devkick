import 'package:flutter/material.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/models/command.dart';
import 'package:devkick/core/models/command_session.dart';
import 'package:devkick/features/terminal/presentation/widgets/terminal_tab.dart';

class TerminalContainer extends StatefulWidget {
  final List<CommandSession> sessions;
  final Function(String) onTerminate;
  final Function(CommandSession) onSessionUpdated;
  final Function(Command) onAddSession;

  const TerminalContainer({
    super.key,
    required this.sessions,
    required this.onTerminate,
    required this.onSessionUpdated,
    required this.onAddSession,
  });

  @override
  State<TerminalContainer> createState() => _TerminalContainerState();
}

class _TerminalContainerState extends State<TerminalContainer> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  final Map<String, GlobalKey> _tabKeys = {};

  @override
  void initState() {
    super.initState();
    _initTabController();
    _initTabKeys();
  }

  void _initTabController() {
    _tabController = TabController(
      length: widget.sessions.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabChange);
  }

  void _initTabKeys() {
    // Create keys for new sessions
    for (final session in widget.sessions) {
      if (!_tabKeys.containsKey(session.id)) {
        _tabKeys[session.id] = GlobalKey();
      }
    }
  }

  @override
  void didUpdateWidget(TerminalContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Create keys for new sessions
    _initTabKeys();
    
    // If the number of sessions changed, update the tab controller
    if (widget.sessions.length != oldWidget.sessions.length) {
      _updateTabController();
    }
  }

  void _updateTabController() {
    final oldIndex = _tabController.index;
    _tabController.dispose();
    _tabController = TabController(
      length: widget.sessions.length, 
      vsync: this,
      initialIndex: oldIndex < widget.sessions.length ? oldIndex : 0,
    );
    _tabController.addListener(_handleTabChange);
    setState(() {
      _currentIndex = _tabController.index;
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging || _currentIndex != _tabController.index) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.terminal,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No active terminals',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Run a command to start a new terminal session',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Tab Bar
        Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            dividerColor: Colors.transparent,
            tabAlignment: TabAlignment.start,
            tabs: widget.sessions.map((session) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(session.command.icon),
                    const SizedBox(width: 8),
                    Text(session.command.label),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => widget.onTerminate(session.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: session.isRunning
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.sessions.map((session) {
              // Use a key to preserve widget state even when order changes
              return TerminalTab(
                key: _tabKeys[session.id] ?? ValueKey('terminal_tab_${session.id}'),
                session: session,
                onSessionUpdated: widget.onSessionUpdated,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
} 