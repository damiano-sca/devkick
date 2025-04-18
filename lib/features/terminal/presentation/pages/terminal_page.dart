import 'dart:async';
import 'package:flutter/material.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/models/command_session.dart';
import 'package:devkick/core/services/command_service.dart';

class TerminalPage extends StatefulWidget {
  final CommandSession session;
  final VoidCallback onTerminate;

  const TerminalPage({
    super.key, 
    required this.session,
    required this.onTerminate,
  });

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  late StreamSubscription<String>? _outputSubscription;
  final ScrollController _scrollController = ScrollController();
  final List<String> _outputLines = [];
  bool _isRunning = true;
  late CommandSession _session;
  late StreamController<String> _outputStreamController;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _outputStreamController = StreamController<String>.broadcast();
    _startProcess();
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
      
      // Update session and clear previous output
      setState(() {
        _session = widget.session;
        _outputLines.clear();
        _isRunning = true;
      });
      
      // Start the new process
      _startProcess();
    }
  }

  void _startProcess() async {
    try {
      // Call startProcess and get the process ID
      final processId = await CommandService.startProcess(
        _session.command.command,
        terminalType: _session.command.terminalType,
        onStdout: (data) {
          setState(() {
            _outputLines.add(data);
          });
          _outputStreamController.add(data);
          _scrollToBottom();
        },
        onStderr: (error) {
          setState(() {
            _outputLines.add(error);
          });
          _outputStreamController.add(error);
          _scrollToBottom();
        },
        onExit: (code) {
          setState(() {
            _isRunning = false;
            _outputLines.add('\n[Process exited with code: $code]');
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
      });
    }
  }

  void _terminateProcess() {
    if (_isRunning) {
      CommandService.killProcess(_session.id);
      setState(() {
        _outputLines.add('[Process terminated by user]');
        _isRunning = false;
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