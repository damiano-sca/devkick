import 'dart:async';
import 'package:devkick/core/models/command.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:devkick/core/models/routine.dart';
import 'package:devkick/core/services/command_service.dart';
import 'package:devkick/core/models/process_result.dart';

class RoutineService {
  static final List<Routine> _routines = [];
  static final Uuid _uuid = const Uuid();
  static const String _routinesKey = 'routines';
  
  // Get all routines
  static Future<List<Routine>> getRoutines({bool forceRefresh = false}) async {
    if (_routines.isEmpty || forceRefresh) {
      await _loadRoutines();
    }
    return List<Routine>.from(_routines);
  }
  
  // Load routines from SharedPreferences
  static Future<void> _loadRoutines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routineData = prefs.getStringList(_routinesKey);
      
      if (routineData != null) {
        _routines.clear();
        
        for (final data in routineData) {
          try {
            final json = jsonDecode(data);
            final routine = Routine.fromJson(json);
            _routines.add(routine);
          } catch (e) {
            debugPrint('Error parsing routine: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading routines: $e');
    }
  }
  
  // Save routines to SharedPreferences
  static Future<bool> _saveRoutines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routineData = _routines.map((routine) {
        return jsonEncode(routine.toJson());
      }).toList();
      
      return await prefs.setStringList(_routinesKey, routineData);
    } catch (e) {
      debugPrint('Error saving routines: $e');
      return false;
    }
  }
  
  // Add a new routine
  static Future<bool> addRoutine(Routine routine) async {
    try {
      final newRoutine = routine.copyWith(
        id: _uuid.v4(),
      );
      _routines.add(newRoutine);
      return await _saveRoutines();
    } catch (e) {
      debugPrint('Error adding routine: $e');
      return false;
    }
  }
  
  // Update an existing routine
  static Future<bool> updateRoutine(String routineId, Routine updatedRoutine) async {
    try {
      final index = _routines.indexWhere((r) => r.id == routineId);
      if (index != -1) {
        _routines[index] = updatedRoutine.copyWith(id: routineId);
        return await _saveRoutines();
      }
      return false;
    } catch (e) {
      debugPrint('Error updating routine: $e');
      return false;
    }
  }
  
  // Delete a routine
  static Future<bool> deleteRoutine(String routineId) async {
    try {
      _routines.removeWhere((routine) => routine.id == routineId);
      return await _saveRoutines();
    } catch (e) {
      debugPrint('Error deleting routine: $e');
      return false;
    }
  }
  
  // Execute a routine
  static Future<List<Map<Command, ProcessResult>>> executeRoutine(Routine routine) async {
    final results = <Map<Command, ProcessResult>>[];
    
    if (routine.runInParallel) {
      // Run commands in parallel
      final futures = routine.commands.map((command) async {
        final result = await CommandService.executeCommand(
          command.command, 
          terminalType: command.terminalType
        );
        return {command: result};
      }).toList();
      
      final futureResults = await Future.wait(futures);
      results.addAll(futureResults);
    } else {
      // Run commands sequentially
      for (final command in routine.commands) {
        final result = await CommandService.executeCommand(
          command.command, 
          terminalType: command.terminalType
        );
        results.add({command: result});
      }
    }
    
    return results;
  }
  
  // Get commands from a routine without executing them
  static List<Command> getRoutineCommands(Routine routine) {
    return routine.commands;
  }
  
  // Public methods for backup/restore
  static Map<String, dynamic> routineToJson(Routine routine) {
    return routine.toJson();
  }
  
  static Routine routineFromJson(Map<String, dynamic> json) {
    return Routine.fromJson(json);
  }
  
  // Add or update a routine
  static Future<bool> addOrUpdateRoutine(Routine routine) async {
    try {
      final index = _routines.indexWhere((r) => r.id == routine.id);
      
      if (index >= 0) {
        // Update existing routine
        _routines[index] = routine;
      } else {
        // Add new routine
        _routines.add(routine);
      }
      
      return await _saveRoutines();
    } catch (e) {
      debugPrint('Error adding/updating routine: $e');
      return false;
    }
  }
  
  // Refresh routines from storage
  static Future<void> refreshRoutines() async {
    await _loadRoutines();
  }
} 