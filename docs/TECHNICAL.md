# DevKick Technical Documentation

This document provides an in-depth technical overview of the DevKick application, explaining its architecture, data flow, and key components.

## Architecture Overview

DevKick follows a clean architecture approach with a feature-first organization. The application is divided into core components (shared across features) and feature modules (specific functionality).

### Architecture Layers

1. **Presentation Layer**
   - UI components (widgets, screens)
   - State management
   - User interaction

2. **Domain Layer**
   - Business logic
   - Models
   - Use cases

3. **Data Layer**
   - Data sources
   - Storage
   - External services

## Data Flow

### Command Management Flow

1. User creates a command via the UI
2. CommandService validates and stores the command
3. UI updates to display the new command
4. Command is persisted to local storage using SharedPreferences

### Command Execution Flow

1. User selects a command to run
2. AppShell creates a CommandSession and updates navigation
3. TerminalPage starts a process via CommandService
4. Process output is streamed back to TerminalPage
5. UI updates in real-time with command output
6. Session state is preserved when navigating between tabs

## Key Components

### Core Models

#### Command

The `Command` model represents a terminal command that can be executed:

```dart
class Command {
  final String id;
  final String label;
  final String command;
  final String category;
  final IconData icon;
  final bool showTerminalOutput;
  final TerminalType terminalType;
  
  // Constructor, factory methods, and utility functions
}
```

#### CommandSession

The `CommandSession` model tracks the execution state of a command:

```dart
class CommandSession {
  final String id;
  final Command command;
  final String output;
  final String error;
  final int exitCode;
  final bool isRunning;
  final DateTime startTime;
  final bool completed;
  final List<String> outputLines;
  
  // Constructor and utility functions
}
```

#### Routine

The `Routine` model represents a group of commands that can be executed together:

```dart
class Routine {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<Command> commands;
  final bool runInParallel;
  
  // Constructor, factory methods, and utility functions
}
```

### Core Services

#### CommandService

The `CommandService` handles command management and execution:

- Stores and retrieves commands from local storage
- Executes commands in various terminal types
- Manages process lifecycles
- Provides output streaming

#### RoutineService

The `RoutineService` manages routines:

- Stores and retrieves routines from local storage
- Executes multiple commands as part of a routine
- Handles sequential and parallel execution

#### SettingsService

The `SettingsService` manages application settings:

- Terminal path configuration
- Theme preferences
- Other user preferences

### UI Components

#### AppShell

The `AppShell` is the main container for the application:

- Navigation rail for switching between features
- Manages command sessions
- Coordinates navigation between views

#### TerminalPage

The `TerminalPage` handles command execution and display:

- Process execution via CommandService
- Real-time output display
- Session state management

## State Management

DevKick uses a simple state management approach:

1. **StatefulWidget State** for UI state
2. **Service Classes** for business logic and data management
3. **Callbacks** for parent-child communication
4. **SharedPreferences** for persistent storage

## Storage Strategy

Application data is stored using `SharedPreferences`:

- Commands are stored as JSON strings
- Routines are stored as JSON strings
- Settings are stored as primitive values
- The BackupService provides import/export functionality

## Process Execution

DevKick executes commands using Dart's `Process` API:

1. Determines the appropriate terminal based on TerminalType
2. Builds command arguments based on the terminal
3. Starts a process with `Process.start()`
4. Streams stdout and stderr to listeners
5. Tracks process state and exit code

## Navigation

The application uses Flutter's built-in navigation with a custom approach:

1. Main navigation via the NavigationRail in AppShell
2. Terminal sessions are managed within AppShell
3. Settings and other modal screens use standard route navigation

## Performance Considerations

- Terminal output is rendered efficiently using Stream-based updates
- Command sessions maintain their state when navigating between tabs
- Process management ensures resources are properly cleaned up

## Error Handling

- Commands that fail to execute show error output in the terminal
- Services include error handling and reporting
- UI provides feedback for operations like saving and deleting commands

## Extensibility

DevKick's architecture allows for easy extension:

1. **New Features**: Add a new directory under features/
2. **New Command Types**: Extend the Command model and CommandService
3. **Additional Platforms**: The UI is responsive and adaptable to different platforms

## Testing Strategy

The application can be tested at multiple levels:

1. **Unit Tests**: For model and service logic
2. **Widget Tests**: For UI components
3. **Integration Tests**: For end-to-end flows 