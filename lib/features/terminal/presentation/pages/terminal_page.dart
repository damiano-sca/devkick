import 'dart:async';
import 'package:flutter/material.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/models/command_session.dart';
import 'package:devkick/core/services/command_service.dart';

class TerminalPage extends StatefulWidget {
  final CommandSession session;
  final VoidCallback onTerminate;
  final Function(CommandSession)? onSessionUpdated;

  const TerminalPage({
    super.key, 
    required this.session,
    required this.onTerminate,
    this.onSessionUpdated,
  });

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  late StreamSubscription<String>? _outputSubscription;
  final ScrollController _scrollController = ScrollController();
  List<String> _outputLines = [];
  bool _isRunning = true;
  late CommandSession _session;
  late StreamController<String> _outputStreamController;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _outputStreamController = StreamController<String>.broadcast();
    
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

  @override
  void didUpdateWidget(TerminalPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the session changed (user navigated to a different terminal)
    if (widget.session.id != oldWidget.session.id) {
      // Cancel the old subscription and close the stream controller
      _outputSubscription?.cancel();
      _outputStreamController.close();
      
      // Create a new stream controller
      _outputStreamController = StreamController<String>.broadcast();
      
      // Update session and check if it's already been completed
      setState(() {
        _session = widget.session;
        
        if (_session.completed) {
          // If the session has already been completed, just load its output
          _outputLines = List.from(_session.outputLines);
          _isRunning = _session.isRunning;
          // Schedule scroll to bottom for after the build
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        } else {
          // Check if there's an active process already
          final processActive = CommandService.isProcessActive(_session.id);
          
          if (processActive) {
            // Process is already running in the background, reconnect to it
            _reconnectToProcess();
          } else {
            // Get previously stored output, if any
            final storedOutput = CommandService.getProcessOutput(_session.id);
            if (storedOutput.isNotEmpty) {
              // We have output but process isn't active anymore
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
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            } else {
              // No stored output and no active process - start a new one
              _outputLines = [];
              _isRunning = true;
              _startProcess();
            }
          }
        }
      });
    }
  }

  void _startProcess() async {
    try {
      // Call startProcess and get the process ID
      final processId = await CommandService.startProcess(
        _session.command.command,
        terminalType: _session.command.terminalType,
        commandObj: _session.command,
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
    
    // Invoke the callback to remove this terminal from navigation
    widget.onTerminate();
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
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_session.command.label),
        actions: [
          IconButton(
            icon: Icon(
              _isRunning ? Icons.stop : Icons.close,
              color: _isRunning ? theme.colorScheme.error : null,
            ),
            tooltip: _isRunning ? 'Stop Process' : 'Close Terminal',
            onPressed: _terminateProcess,
          ),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.smallPadding),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: SelectableText(
                  _outputLines.join(''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
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
      ),
    );
  }
} 