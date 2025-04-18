import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:devkick/core/models/command.dart';
import 'package:devkick/core/models/routine.dart';
import 'package:devkick/core/services/command_service.dart';
import 'package:devkick/core/services/routine_service.dart';

class BackupService {
  // Export commands and routines to a JSON file
  static Future<String?> exportData() async {
    try {
      // Get all commands and routines
      final commands = await CommandService.getAllCommands();
      final routines = await RoutineService.getRoutines();

      // Create backup object
      final backup = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'commands': commands.map((command) => command.toJson()).toList(),
        'routines': routines.map((routine) => routine.toJson()).toList(),
      };

      // Convert to JSON
      final jsonString = jsonEncode(backup);
      
      // Let the user choose where to save the file
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save backup file',
        fileName: 'devkick_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null) {
        // Save to the selected file
        final file = File(result);
        await file.writeAsString(jsonString);
        return result;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error exporting data: $e');
      return null;
    }
  }

  // Import commands and routines from a JSON file
  static Future<bool> importData() async {
    try {
      // Let the user choose a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      // Read the file
      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      
      // Parse JSON
      final backup = jsonDecode(jsonString);
      
      // Extract commands and routines
      if (backup['commands'] != null) {
        final List<dynamic> commandsJson = backup['commands'];
        final commands = commandsJson.map((json) => Command.fromJson(json)).toList();
        
        // Save all commands
        await CommandService.saveCommands(commands);
      }
      
      if (backup['routines'] != null) {
        final List<dynamic> routinesJson = backup['routines'];
        final routines = routinesJson.map((json) => Routine.fromJson(json)).toList();
        
        // Save all routines
        for (final routine in routines) {
          await RoutineService.addOrUpdateRoutine(routine);
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return false;
    }
  }
} 