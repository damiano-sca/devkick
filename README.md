# DevKick

! This project is made almost exclusively by prompting using Claude 3.7, it's a test to check it's capabilities

A powerful developer productivity tool built with Flutter that helps manage, organize, and execute terminal commands with ease.

![DevKick Logo](assets/devkick-logo.png) <!-- Add a logo image file if available -->

## Features

- **Command Management**
  - Save and organize frequently used terminal commands
  - Group commands into customizable categories
  - Add descriptive labels and icons for quick identification
  - Support for multiple terminal types (Command Prompt, Bash, PowerShell)

- **Command Execution**
  - Run commands with a single click
  - View real-time output in the integrated terminal
  - Navigate between active command sessions
  - Run commands in background when needed

- **Automation with Routines**
  - Group multiple commands into reusable routines
  - Execute commands in sequence or parallel
  - Save time on repetitive tasks

- **Modern UI**
  - Clean Material 3 design
  - Intuitive navigation with side rail
  - Dark and light theme support
  - Responsive layout for various screen sizes

## Getting Started

### Prerequisites

- Flutter SDK (3.7.2 or later)
- Development environment for your platform:
  - Windows: Visual Studio or VS Code
  - macOS: Xcode or VS Code
  - Linux: Any IDE with Flutter support

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/devkick.git
```

2. Navigate to the project directory:
```bash
cd devkick
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app for your platform:
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

## Documentation

### For Users
- [Quick Start Guide](docs/QUICK_START.md) - Get up and running quickly
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Solutions to common issues

### For Developers
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute to DevKick
- [Technical Documentation](docs/TECHNICAL.md) - Architecture and implementation details
- [Adding Features](docs/ADDING_FEATURES.md) - Guide to implementing new features

## Project Structure

The project follows a clean architecture approach with a feature-first organization:

```
lib/
  core/                 # Core functionality shared across features
    constants/          # Application constants
    models/             # Core data models
    services/           # Core services
    theme/              # Theme configuration
    widgets/            # Reusable widgets
  features/             # Feature modules
    app/                # App shell and main navigation
    home/               # Command management
    routines/           # Routine management
    settings/           # App settings
    terminal/           # Terminal execution
  main.dart             # Entry point
```

## Contributing

We welcome contributions! Please see our [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit pull requests, report issues, and suggest improvements.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Uses [shared_preferences](https://pub.dev/packages/shared_preferences) for local storage
- Uses [uuid](https://pub.dev/packages/uuid) for unique identifier generation
- Uses [file_picker](https://pub.dev/packages/file_picker) for file operations
