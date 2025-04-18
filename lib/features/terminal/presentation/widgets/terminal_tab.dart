import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/models/command_session.dart';
import 'package:devkick/core/services/command_service.dart';

class TerminalTab extends StatefulWidget {
  final CommandSession session;
  final Function(CommandSession)? onSessionUpdated;

  const TerminalTab({
    super.key,
    required this.session,
    this.onSessionUpdated,
  });

  @override
  State<TerminalTab> createState() => _TerminalTabState();
}

class _TerminalTabState extends State<TerminalTab> with AutomaticKeepAliveClientMixin {
  late StreamSubscription<String>? _outputSubscription;
  final ScrollController _scrollController = ScrollController();
  List<String> _outputLines = [];
  bool _isRunning = true;
  late CommandSession _session;
  late StreamController<String> _outputStreamController;
  double _fontSize = 12.0; // Default font size
  static const String _fontSizeKey = 'terminal_font_size';
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true; // Ensure this widget isn't disposed when not visible

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _outputStreamController = StreamController<String>.broadcast();
    _loadFontSize();
    _initializeTerminal();
  }

  // Load font size from preferences
  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _fontSize = prefs.getDouble(_fontSizeKey) ?? 12.0;
      });
    } catch (e) {
      debugPrint('Error loading font size: $e');
    }
  }

  // Save font size to preferences
  Future<void> _saveFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, _fontSize);
    } catch (e) {
      debugPrint('Error saving font size: $e');
    }
  }

  void _initializeTerminal() {
    if (_isInitialized) return;

    // Initialize output lines and running state from session
    if (_session.completed) {
      // Session is marked as completed - load stored output
      _outputLines = List.from(_session.outputLines);
      _isRunning = _session.isRunning;
      // Schedule scroll to bottom for after the build
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      // Check if there's an active process already running with this ID
      final processActive = CommandService.isProcessActive(_session.id);
      
      if (processActive) {
        // Process is already running in the background, reconnect to it
        _reconnectToProcess();
      } else {
        // Get previously stored output, if any
        final storedOutput = CommandService.getProcessOutput(_session.id);
        if (storedOutput.isNotEmpty) {
          // We have output but process isn't active anymore
          setState(() {
            _outputLines = List.from(storedOutput);
            _isRunning = false;
            _session = _session.copyWith(
              isRunning: false,
              completed: true,
              outputLines: _outputLines,
            );
            if (widget.onSessionUpdated != null) {
              widget.onSessionUpdated!(_session);
            }
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        } else {
          // No stored output and no active process - start a new one
          _startProcess();
        }
      }
    }
    
    _isInitialized = true;
  }

  @override
  void didUpdateWidget(TerminalTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update session reference if ID changes, not on every rebuild
    if (oldWidget.session.id != widget.session.id) {
      _session = widget.session;
      _isInitialized = false;
      _initializeTerminal();
    }
  }

  void _reconnectToProcess() {
    // Reconnect to the existing process's output streams
    final success = CommandService.reconnectToProcess(
      _session.id,
      onStdout: (data) {
        setState(() {
          _outputLines.add(data);
          _updateSessionOutputLines();
        });
        _outputStreamController.add(data);
        _scrollToBottom();
      },
      onStderr: (error) {
        setState(() {
          _outputLines.add(error);
          _updateSessionOutputLines();
        });
        _outputStreamController.add(error);
        _scrollToBottom();
      },
      onExit: (code) {
        setState(() {
          _isRunning = false;
          _outputLines.add('\n[Process exited with code: $code]');
          // Mark the session as completed
          _session = _session.copyWith(
            isRunning: false,
            completed: true,
            exitCode: code,
            outputLines: List.from(_outputLines),
          );
          
          // Notify parent about the updated session
          if (widget.onSessionUpdated != null) {
            widget.onSessionUpdated!(_session);
          }
        });
        _outputStreamController.add('\n[Process exited with code: $code]');
        _scrollToBottom();
      },
    );
    
    if (!success) {
      // If reconnection failed, consider starting a new process
      _startProcess();
    } else {
      // Update running state
      setState(() {
        _isRunning = CommandService.isProcessActive(_session.id);
      });
    }
  }

  void _startProcess() async {
    try {
      // Call startProcess and get the process ID
      final processId = await CommandService.startProcess(
        _session.command.command,
        terminalType: _session.command.terminalType,
        commandObj: _session.command, // Pass the command object for tracking
        onStdout: (data) {
          setState(() {
            _outputLines.add(data);
            // Update the session's outputLines
            _updateSessionOutputLines();
          });
          _outputStreamController.add(data);
          _scrollToBottom();
        },
        onStderr: (error) {
          setState(() {
            _outputLines.add(error);
            // Update the session's outputLines
            _updateSessionOutputLines();
          });
          _outputStreamController.add(error);
          _scrollToBottom();
        },
        onExit: (code) {
          setState(() {
            _isRunning = false;
            _outputLines.add('\n[Process exited with code: $code]');
            // Mark the session as completed
            _session = _session.copyWith(
              isRunning: false,
              completed: true,
              exitCode: code,
              outputLines: List.from(_outputLines),
            );
            
            // Notify parent about the updated session
            if (widget.onSessionUpdated != null) {
              widget.onSessionUpdated!(_session);
            }
          });
          _outputStreamController.add('\n[Process exited with code: $code]');
          _scrollToBottom();
        },
      );
      
      // Update session ID if needed
      if (processId.isNotEmpty && processId != _session.id) {
        setState(() {
          _session = _session.copyWith(id: processId);
        });
      }
      
      // Listen to our own stream controller
      _outputSubscription = _outputStreamController.stream.listen(null);
    } catch (e) {
      setState(() {
        _outputLines.add('[ERROR] Failed to start process: $e');
        _isRunning = false;
        // Mark the session as completed with error
        _session = _session.copyWith(
          isRunning: false,
          completed: true,
          error: e.toString(),
          outputLines: List.from(_outputLines),
        );
        
        // Notify parent about the updated session
        if (widget.onSessionUpdated != null) {
          widget.onSessionUpdated!(_session);
        }
      });
    }
  }

  // Helper to update the session's output lines
  void _updateSessionOutputLines() {
    _session = _session.copyWith(
      outputLines: List.from(_outputLines),
    );
    // Notify parent about the updated session
    if (widget.onSessionUpdated != null) {
      widget.onSessionUpdated!(_session);
    }
  }

  void _terminateProcess() {
    if (_isRunning) {
      CommandService.killProcess(_session.id);
      setState(() {
        _outputLines.add('[Process terminated by user]');
        _isRunning = false;
        // Mark the session as completed when terminated
        _session = _session.copyWith(
          isRunning: false,
          completed: true,
          outputLines: List.from(_outputLines),
        );
        
        // Notify parent about the updated session
        if (widget.onSessionUpdated != null) {
          widget.onSessionUpdated!(_session);
        }
      });
      _scrollToBottom();
    }
  }

  // Increase font size
  void _increaseFontSize() {
    setState(() {
      _fontSize = _fontSize + 1;
      _saveFontSize();
    });
  }

  // Decrease font size
  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > 8) { // Minimum font size
        _fontSize = _fontSize - 1;
        _saveFontSize();
      }
    });
  }

  // Reset font size to default
  void _resetFontSize() {
    setState(() {
      _fontSize = 12.0; // Default font size
      _saveFontSize();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    // Just cancel our local subscription, but don't kill the process
    // so it can continue running in the background
    _outputSubscription?.cancel();
    _outputStreamController.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Command info bar
        Container(
          padding: const EdgeInsets.all(AppConstants.smallPadding),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Icon(
                Icons.terminal,
                color: theme.colorScheme.onSurface,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _session.command.command,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Font size controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _decreaseFontSize,
                    tooltip: 'Decrease font size',
                    iconSize: 18,
                  ),
                  Text(
                    '${_fontSize.toInt()}px',
                    style: theme.textTheme.bodySmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _increaseFontSize,
                    tooltip: 'Increase font size',
                    iconSize: 18,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _resetFontSize,
                    tooltip: 'Reset font size',
                    iconSize: 18,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _isRunning
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isRunning ? 'RUNNING' : 'FINISHED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _isRunning
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        
        // Terminal output
        Expanded(
          child: Container(
            color: Colors.black,
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.smallPadding),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SelectableText(
                _outputLines.join(''),
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: _fontSize,
                ),
              ),
            ),
          ),
        ),
        
        // Stop button (only if running)
        if (_isRunning)
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Process'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: _terminateProcess,
                ),
              ],
            ),
          ),
      ],
    );
  }
} 