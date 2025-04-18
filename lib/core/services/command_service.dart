import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devkick/core/models/command.dart';
import 'package:devkick/core/services/settings_service.dart';
import 'package:devkick/core/models/process_result.dart';

/// Service for managing commands and executing them
class CommandService {
  /// In-memory list of commands
  static final List<Command> _commands = [];
  
  /// Active process map (processId -> Process instance)
  static final Map<String, Process> _activeProcesses = {};
  
  /// Key for storing commands in SharedPreferences
  static const String _commandsKey = 'commands';
  
  /// Key for storing routines in SharedPreferences
  static const String _routinesKey = 'routines';
  
  /// Flag to track initialization state
  static bool _initialized = false;

  /// Initialize the service by loading commands from storage
  static Future<void> init() async {
    if (!_initialized) {
      await _loadFromStorage();
      _initialized = true;
    }
  }

  /// Get all commands, loading from storage if needed
  static Future<List<Command>> getAllCommands() async {
    if (!_initialized) {
      await init();
    }
    return List<Command>.from(_commands);
  }

  /// Get a command by its ID
  static Future<Command?> getCommandById(String id) async {
    await init();
    try {
      return _commands.firstWhere((command) => command.id == id);
    } catch (e) {
      debugPrint('Error getting command by ID: $e');
      return null;
    }
  }

  /// Get commands by category
  static Future<List<Command>> getCommandsByCategory(String category) async {
    await init();
    try {
      return _commands.where((command) => command.category == category).toList();
    } catch (e) {
      debugPrint('Error getting commands by category: $e');
      return [];
    }
  }

  /// Save a command (add or update)
  /// Returns a map with 'success' status and 'updatedRoutines' count
  static Future<Map<String, dynamic>> saveCommand(Command command) async {
    await init();
    try {
      final index = _commands.indexWhere((c) => c.id == command.id);
      int updatedRoutines = 0;
      
      if (index >= 0) {
        // Update existing command
        _commands[index] = command;
        
        // Update the command in all routines that include it
        updatedRoutines = await _updateCommandInRoutines(command);
      } else {
        // Add new command
        _commands.add(command);
      }
      
      final success = await _saveToStorage();
      return {
        'success': success,
        'updatedRoutines': updatedRoutines,
      };
    } catch (e) {
      debugPrint('Error saving command: $e');
      return {
        'success': false,
        'updatedRoutines': 0,
      };
    }
  }

  /// Update command in all routines
  static Future<int> _updateCommandInRoutines(Command command) async {
    try {
      // Read routines directly from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final routineData = prefs.getStringList(_routinesKey);
      
      if (routineData == null || routineData.isEmpty) return 0;
      
      bool anyRoutineUpdated = false;
      List<String> updatedRoutines = [];
      int updatedCount = 0;
      
      // Process each routine
      for (final routineJson in routineData) {
        try {
          // Parse the routine
          final Map<String, dynamic> routineMap = jsonDecode(routineJson);
          
          // Check if this routine contains the command
          bool routineUpdated = false;
          
          if (routineMap.containsKey('commands') && routineMap['commands'] is List) {
            final commands = routineMap['commands'] as List;
            final updatedCommands = [];
            
            for (final cmd in commands) {
              if (cmd is Map<String, dynamic> && 
                  cmd.containsKey('id') && 
                  cmd['id'] == command.id) {
                // Found the command, replace with updated version
                updatedCommands.add(command.toJson());
                routineUpdated = true;
                anyRoutineUpdated = true;
              } else {
                // Keep original command
                updatedCommands.add(cmd);
              }
            }
            
            if (routineUpdated) {
              updatedCount++;
              // Update the commands in the routine
              routineMap['commands'] = updatedCommands;
              // Add to our updated list
              updatedRoutines.add(jsonEncode(routineMap));
            } else {
              // No change, keep original
              updatedRoutines.add(routineJson);
            }
          } else {
            // No commands or invalid format, keep original
            updatedRoutines.add(routineJson);
          }
        } catch (e) {
          // Error processing this routine, keep original
          debugPrint('Error processing routine during command update: $e');
          updatedRoutines.add(routineJson);
        }
      }
      
      // Save updated routines if any were changed
      if (anyRoutineUpdated) {
        await prefs.setStringList(_routinesKey, updatedRoutines);
        debugPrint('Updated command in $updatedCount routines: ${command.label}');
      }
      
      return updatedCount;
    } catch (e) {
      debugPrint('Error updating command in routines: $e');
      return 0;
    }
  }

  /// Delete a command by ID
  /// Returns a map with 'success' status and 'updatedRoutines' count
  static Future<Map<String, dynamic>> deleteCommand(String commandId) async {
    await init();
    try {
      // Find the command before deleting it so we can update routines
      final commandIndex = _commands.indexWhere((c) => c.id == commandId);
      
      if (commandIndex >= 0) {
        // First, remove the command from all routines
        final updatedRoutines = await _removeCommandFromRoutines(commandId);
        
        // Then delete the command from our list
        _commands.removeAt(commandIndex);
        
        final success = await _saveToStorage();
        return {
          'success': success,
          'updatedRoutines': updatedRoutines,
        };
      } else {
        // Command not found
        return {
          'success': false,
          'updatedRoutines': 0,
        };
      }
    } catch (e) {
      debugPrint('Error deleting command: $e');
      return {
        'success': false,
        'updatedRoutines': 0,
      };
    }
  }

  /// Remove a command from all routines
  static Future<int> _removeCommandFromRoutines(String commandId) async {
    try {
      // Read routines directly from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final routineData = prefs.getStringList(_routinesKey);
      
      if (routineData == null || routineData.isEmpty) return 0;
      
      bool anyRoutineUpdated = false;
      List<String> updatedRoutines = [];
      int updatedCount = 0;
      
      // Process each routine
      for (final routineJson in routineData) {
        try {
          // Parse the routine
          final Map<String, dynamic> routineMap = jsonDecode(routineJson);
          
          // Check if this routine contains the command
          bool routineUpdated = false;
          
          if (routineMap.containsKey('commands') && routineMap['commands'] is List) {
            final commands = routineMap['commands'] as List;
            final updatedCommands = [];
            
            for (final cmd in commands) {
              if (cmd is Map<String, dynamic> && 
                  cmd.containsKey('id') && 
                  cmd['id'] == commandId) {
                // Skip this command (removing it)
                routineUpdated = true;
                anyRoutineUpdated = true;
              } else {
                // Keep other commands
                updatedCommands.add(cmd);
              }
            }
            
            if (routineUpdated) {
              updatedCount++;
              // Update the commands in the routine
              routineMap['commands'] = updatedCommands;
              // Add to our updated list
              updatedRoutines.add(jsonEncode(routineMap));
            } else {
              // No change, keep original
              updatedRoutines.add(routineJson);
            }
          } else {
            // No commands or invalid format, keep original
            updatedRoutines.add(routineJson);
          }
        } catch (e) {
          // Error processing this routine, keep original
          debugPrint('Error processing routine during command removal: $e');
          updatedRoutines.add(routineJson);
        }
      }
      
      // Save updated routines if any were changed
      if (anyRoutineUpdated) {
        await prefs.setStringList(_routinesKey, updatedRoutines);
        debugPrint('Removed command from $updatedCount routines');
      }
      
      return updatedCount;
    } catch (e) {
      debugPrint('Error removing command from routines: $e');
      return 0;
    }
  }

  /// Save all commands to storage at once
  static Future<bool> saveCommands(List<Command> commands) async {
    try {
      _commands.clear();
      _commands.addAll(commands);
      return await _saveToStorage();
    } catch (e) {
      debugPrint('Error saving commands: $e');
      return false;
    }
  }

  /// Private method to save commands to SharedPreferences
  static Future<bool> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final commandsJson = _commands.map((command) {
        return jsonEncode(command.toJson());
      }).toList();
      
      return await prefs.setStringList(_commandsKey, commandsJson);
    } catch (e) {
      debugPrint('Error saving commands to storage: $e');
      return false;
    }
  }

  /// Private method to load commands from SharedPreferences
  static Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commandsJson = prefs.getStringList(_commandsKey);
      
      if (commandsJson != null) {
        _commands.clear();
        
        for (final jsonString in commandsJson) {
          try {
            final json = jsonDecode(jsonString);
            final command = Command.fromJson(json);
            _commands.add(command);
          } catch (e) {
            debugPrint('Error parsing command JSON: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading commands from storage: $e');
    }
  }

  /// Execute a command and return ProcessResult
  static Future<ProcessResult> executeCommand(String command, {TerminalType terminalType = TerminalType.prompt}) async {
    // Get the terminal path based on the terminal type
    final terminalPath = await SettingsService.getTerminalPath(terminalType);
    
    // Determine which shell to use based on terminal type
    String executable;
    List<String> arguments;
    
    switch (terminalType) {
      case TerminalType.prompt:
        executable = terminalPath;
        arguments = ['/c', command];
        break;
      case TerminalType.bash:
        executable = terminalPath;
        arguments = ['-c', command];
        break;
      case TerminalType.powershell:
        executable = terminalPath;
        arguments = ['-Command', command];
        break;
    }
    
    debugPrint('Executing command: $command');
    debugPrint('Terminal type: ${SettingsService.getTerminalTypeName(terminalType)}');
    debugPrint('Executable: $executable');
    debugPrint('Arguments: $arguments');
    
    try {
      final result = await Process.run(
        executable,
        arguments,
        runInShell: false,
      );
      
      // Convert native ProcessResult to our custom ProcessResult
      return ProcessResult(
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
      );
    } catch (e) {
      debugPrint('Error executing command: $e');
      // Return a custom ProcessResult with the error
      return ProcessResult(
        exitCode: -1,
        stdout: '',
        stderr: e.toString(),
      );
    }
  }

  /// Start a long-running process
  static Future<String> startProcess(String command, {
    TerminalType terminalType = TerminalType.prompt,
    Function(String)? onStdout,
    Function(String)? onStderr,
    Function(int)? onExit,
  }) async {
    // Generate a unique ID for this process
    final processId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Get the terminal path based on the terminal type
    final terminalPath = await SettingsService.getTerminalPath(terminalType);
    
    // Determine which shell to use based on terminal type
    String executable;
    List<String> arguments;
    
    switch (terminalType) {
      case TerminalType.prompt:
        executable = terminalPath;
        arguments = ['/c', command];
        break;
      case TerminalType.bash:
        executable = terminalPath;
        arguments = ['-c', command];
        break;
      case TerminalType.powershell:
        executable = terminalPath;
        arguments = ['-Command', command];
        break;
    }
    
    try {
      final process = await Process.start(
        executable,
        arguments,
        runInShell: false,
      );
      
      _activeProcesses[processId] = process;
      
      // Set up stream listeners if callbacks are provided
      if (onStdout != null) {
        process.stdout.transform(utf8.decoder).listen(onStdout);
      }
      
      if (onStderr != null) {
        process.stderr.transform(utf8.decoder).listen(onStderr);
      }
      
      // Handle process exit
      process.exitCode.then((exitCode) {
        _activeProcesses.remove(processId);
        if (onExit != null) {
          onExit(exitCode);
        }
      });
      
      return processId;
    } catch (e) {
      debugPrint('Error starting process: $e');
      if (onStderr != null) {
        onStderr(e.toString());
      }
      if (onExit != null) {
        onExit(-1);
      }
      return '';
    }
  }

  /// Kill a running process
  static void killProcess(String processId) {
    final process = _activeProcesses[processId];
    if (process != null) {
      process.kill();
      _activeProcesses.remove(processId);
    }
  }

  /// Kill all running processes
  static void killAllProcesses() {
    _activeProcesses.forEach((_, process) {
      process.kill();
    });
    _activeProcesses.clear();
  }
} 