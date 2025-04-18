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

class _TerminalContainerState extends State<TerminalContainer> with TickerProviderStateMixin {
  TabController? _tabController;
  int _currentIndex = 0;
  final Map<String, GlobalKey> _tabKeys = {};
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _initTabKeys();
    _initTabController();
  }

  void _initTabController() {
    if (_isDisposed || !mounted) return;
    
    if (widget.sessions.isNotEmpty) {
      _tabController = TabController(
        length: widget.sessions.length,
        vsync: this,
        initialIndex: _currentIndex < widget.sessions.length ? _currentIndex : 0,
      );
      if (!_isDisposed && mounted) {
        _tabController?.addListener(_handleTabChange);
      }
    }
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
    
    if (_isDisposed || !mounted) return;
    
    // Create keys for new sessions
    _initTabKeys();
    
    // If the number of sessions changed, update the tab controller
    if (widget.sessions.length != oldWidget.sessions.length || _tabController == null) {
      _updateTabController();
    }
  }

  void _updateTabController() {
    if (_isDisposed || !mounted) return;
    
    if (_tabController != null) {
      _tabController!.removeListener(_handleTabChange);
      
      // Safe dispose with error handling
      try {
        _tabController!.dispose();
      } catch (e) {
        // Ignore if already disposed
        debugPrint('TabController dispose error (likely already disposed): $e');
      }
      
      _tabController = null;
    }
    
    if (widget.sessions.isEmpty) {
      _currentIndex = 0;
      return;
    }
    
    // Create new controller with deferred execution to avoid initialization race conditions
    Future.microtask(() {
      if (_isDisposed || !mounted) return;
      
      final safeIndex = _currentIndex < widget.sessions.length ? _currentIndex : 0;
      _tabController = TabController(
        length: widget.sessions.length, 
        vsync: this,
        initialIndex: safeIndex,
      );
      
      if (!_isDisposed && mounted) {
        _tabController?.addListener(_handleTabChange);
        setState(() {
          _currentIndex = safeIndex;
        });
      }
    });
  }

  void _handleTabChange() {
    if (_isDisposed || !mounted || _tabController == null) return;
    
    if (_tabController!.indexIsChanging || _currentIndex != _tabController!.index) {
      if (mounted) {
        setState(() {
          _currentIndex = _tabController!.index;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_tabController != null) {
      _tabController!.removeListener(_handleTabChange);
      
      // Safe dispose with error handling
      try {
        _tabController!.dispose();
      } catch (e) {
        // Ignore if already disposed
        debugPrint('TabController dispose error (likely already disposed): $e');
      }
      
      _tabController = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return const SizedBox.shrink();
    
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

    // Ensure tab controller is properly initialized with the correct length
    if (_tabController == null || _tabController!.length != widget.sessions.length) {
      // Schedule a rebuild with a microtask to avoid build phase conflicts
      Future.microtask(() {
        if (mounted && !_isDisposed) {
          _updateTabController();
          // Trigger a rebuild after the microtask is complete
          if (mounted) setState(() {});
        }
      });
      
      // Show loading while waiting for controller to initialize
      return const Center(child: CircularProgressIndicator());
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
        
        // Tab Content - Use a Builder to ensure proper context for the controller
        Expanded(
          child: Builder(
            builder: (context) {
              // Additional safety check
              if (_tabController == null || _tabController!.length != widget.sessions.length) {
                return const Center(child: CircularProgressIndicator());
              }
              
              // Create TabBarView
              return TabBarView(
                controller: _tabController,
                children: widget.sessions.map((session) {
                  // Use a key to preserve widget state even when order changes
                  return TerminalTab(
                    key: _tabKeys[session.id] ?? GlobalKey(),
                    session: session,
                    onSessionUpdated: widget.onSessionUpdated,
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
} 