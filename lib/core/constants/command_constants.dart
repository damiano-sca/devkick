import 'package:flutter/material.dart';

/// Constants related to command items, shared between multiple widgets
class CommandConstants {
  /// List of predefined categories for commands
  static const List<String> predefinedCategories = [
    'General',
    'Development',
    'Database',
    'Testing',
    'Deployment',
    'Utilities',
    'System',
    'Network',
    'Security',
    'Docker',
    'Git',
    'Web',
    'Mobile',
  ];

  /// List of available icons to choose from
  static const List<IconData> availableIcons = [
    // General icons
    Icons.code,
    Icons.terminal,
    Icons.folder,
    Icons.settings,
    Icons.build,
    Icons.create_new_folder,
    Icons.cleaning_services,
    Icons.update,
    Icons.medical_services,
    Icons.android,
    Icons.web,
    Icons.desktop_windows,
    Icons.text_fields,
    Icons.list,
    Icons.file_copy,
    Icons.drive_folder_upload,
    Icons.precision_manufacturing,
    Icons.cloud_upload,
    Icons.cloud_download,
    
    // Software development icons
    Icons.data_object,         // For objects/data structures
    Icons.integration_instructions, // For software integration
    Icons.memory,              // For low-level/system programming
    Icons.bug_report,          // For debugging/bug reporting
    Icons.download,            // For downloading files
    
    // Database icons
    Icons.storage,             // For database storage
    Icons.table_chart,         // For database tables
    Icons.data_array,          // For data arrays/collections
    
    // Testing icons
    Icons.science,             // For testing/experiments
    Icons.checklist,           // For test cases/verification
    Icons.rule,                // For testing rules
  ];
  
  /// Get an appropriate icon for a category
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return Icons.star;
      case 'development':
        return Icons.code;
      case 'database':
        return Icons.storage;
      case 'testing':
        return Icons.science;
      case 'deployment':
        return Icons.rocket_launch;
      case 'utilities':
        return Icons.handyman;
      case 'system':
        return Icons.computer;
      case 'network':
        return Icons.wifi;
      case 'security':
        return Icons.security;
      case 'docker':
        return Icons.inventory_2;
      case 'git':
        return Icons.merge_type;
      case 'web':
        return Icons.web;
      case 'mobile':
        return Icons.phone_android;
      default:
        return Icons.category;
    }
  }
} 