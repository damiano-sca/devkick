# Adding Features to DevKick

This guide provides a step-by-step approach to adding new features to DevKick, following the project's architecture and coding standards.

## Feature Development Workflow

1. **Understand the Architecture**
   - Review the project structure and existing code
   - Identify where your feature fits into the overall architecture
   - Read the [Technical Documentation](TECHNICAL.md) to understand the system

2. **Create a Feature Plan**
   - Define what the feature will do
   - Sketch the UI if applicable
   - Identify any models, services, or widgets you'll need to create or modify

3. **Implementation**
   - Follow the feature-first approach
   - Build incrementally and test frequently
   - Adhere to the coding guidelines

## Creating a New Feature

### Step 1: Create the Feature Directory

For a new feature called "MyFeature":

```
lib/features/my_feature/
  ├── presentation/
  │   ├── pages/
  │   │   └── my_feature_page.dart
  │   └── widgets/
  │       └── my_feature_widget.dart
  └── domain/
      └── models/
          └── my_feature_model.dart
```

### Step 2: Create the Model (if needed)

Create any data models your feature requires. Place them in `lib/features/my_feature/domain/models/` or `lib/core/models/` if they'll be shared.

```dart
// lib/features/my_feature/domain/models/my_feature_model.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class MyFeatureModel {
  final String id;
  final String name;
  final String description;
  
  MyFeatureModel({
    String? id,
    required this.name,
    required this.description,
  }) : id = id ?? const Uuid().v4();
  
  // Add factory methods, toJson, fromJson, etc.
}
```

### Step 3: Create a Service (if needed)

If your feature requires business logic, create a service class:

```dart
// lib/features/my_feature/domain/services/my_feature_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devkick/features/my_feature/domain/models/my_feature_model.dart';

class MyFeatureService {
  static const String _storageKey = 'my_feature_items';
  static final List<MyFeatureModel> _items = [];
  static bool _initialized = false;
  
  static Future<void> init() async {
    if (!_initialized) {
      await _loadFromStorage();
      _initialized = true;
    }
  }
  
  static Future<List<MyFeatureModel>> getAllItems() async {
    await init();
    return List<MyFeatureModel>.from(_items);
  }
  
  // Add methods for CRUD operations, etc.
  
  static Future<bool> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = _items.map((item) => jsonEncode(item.toJson())).toList();
      return await prefs.setStringList(_storageKey, itemsJson);
    } catch (e) {
      debugPrint('Error saving to storage: $e');
      return false;
    }
  }
  
  static Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getStringList(_storageKey) ?? [];
      
      _items.clear();
      for (final itemJson in itemsJson) {
        try {
          final map = jsonDecode(itemJson) as Map<String, dynamic>;
          _items.add(MyFeatureModel.fromJson(map));
        } catch (e) {
          debugPrint('Error parsing item: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading from storage: $e');
    }
  }
}
```

### Step 4: Create the UI

Create the main page for your feature:

```dart
// lib/features/my_feature/presentation/pages/my_feature_page.dart
import 'package:flutter/material.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/features/my_feature/domain/models/my_feature_model.dart';
import 'package:devkick/features/my_feature/domain/services/my_feature_service.dart';
import 'package:devkick/features/my_feature/presentation/widgets/my_feature_widget.dart';

class MyFeaturePage extends StatefulWidget {
  const MyFeaturePage({super.key});

  @override
  State<MyFeaturePage> createState() => _MyFeaturePageState();
}

class _MyFeaturePageState extends State<MyFeaturePage> {
  List<MyFeatureModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final items = await MyFeatureService.getAllItems();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Feature'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No items found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return MyFeatureWidget(item: item);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add action to create a new item
        },
        tooltip: 'Add New Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Step 5: Create Custom Widgets

Break down complex UI into smaller, reusable widgets:

```dart
// lib/features/my_feature/presentation/widgets/my_feature_widget.dart
import 'package:flutter/material.dart';
import 'package:devkick/features/my_feature/domain/models/my_feature_model.dart';

class MyFeatureWidget extends StatelessWidget {
  final MyFeatureModel item;
  
  const MyFeatureWidget({
    super.key,
    required this.item,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(item.description),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Show options menu
          },
        ),
      ),
    );
  }
}
```

### Step 6: Update the Navigation

Add your feature to the app's navigation in AppShell or the relevant parent widget:

```dart
// In AppShell or relevant navigation component
// Add an import for your new feature page
import 'package:devkick/features/my_feature/presentation/pages/my_feature_page.dart';

// Add a navigation item
NavigationRailDestination(
  icon: Icon(Icons.new_releases_outlined),
  selectedIcon: Icon(Icons.new_releases),
  label: Text('My Feature'),
),

// Update the _buildPage method
Widget _buildPage() {
  if (_selectedIndex == 0) {
    return HomePage(...);
  } else if (_selectedIndex == 1) {
    return RoutinesPage(...);
  } else if (_selectedIndex == 2) {
    // Your new feature
    return const MyFeaturePage();
  } else if (...) {
    // Other pages
  }
}
```

## Testing Your Feature

1. **Manual Testing**
   - Test all functionality thoroughly
   - Check edge cases and error handling
   - Verify UI appearance in both light and dark themes

2. **Unit Tests** (recommended)
   - Create tests for your models and services
   - Place tests in the `test/` directory

```dart
// test/features/my_feature/my_feature_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:devkick/features/my_feature/domain/models/my_feature_model.dart';
import 'package:devkick/features/my_feature/domain/services/my_feature_service.dart';

void main() {
  group('MyFeatureService', () {
    test('should add a new item', () async {
      // Test implementation
    });
    
    test('should get all items', () async {
      // Test implementation
    });
    
    // More tests
  });
}
```

## Integration Guidelines

1. **Follow Existing Patterns**
   - Study similar features in the app
   - Maintain consistency with existing code

2. **Documentation**
   - Add comments to complex functions
   - Update project documentation if needed

3. **Code Quality**
   - Format your code with `flutter format .`
   - Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)

## Common Pitfalls

- **Forgetting to initialize services**: Always call your service's init() method
- **Not handling loading states**: Show progress indicators during async operations
- **Ignoring error handling**: Always catch exceptions and provide user feedback
- **Tight coupling**: Keep your feature components loosely coupled
- **Hard-coded styles**: Use theme properties instead of hard-coded colors

## Example Features for Practice

If you're new to DevKick, try implementing these features:

1. **Command Favorites**: Allow users to mark commands as favorites
2. **Command Search**: Add a search bar to filter commands
3. **Command Export**: Allow exporting individual commands (not just all commands)
4. **Command History**: Track command execution history
5. **Terminal Themes**: Allow customizing the terminal colors 