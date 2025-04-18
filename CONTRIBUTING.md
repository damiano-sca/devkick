# Contributing to DevKick

Thank you for your interest in contributing to DevKick! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Environment Setup](#development-environment-setup)
- [Project Structure](#project-structure)
- [Core Models and Services](#core-models-and-services)
- [Coding Guidelines](#coding-guidelines)
- [Submitting Changes](#submitting-changes)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)

## Code of Conduct

Please be respectful and considerate of others when contributing to this project. We expect all contributors to adhere to basic principles of respect, inclusion, and collaboration.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Set up your development environment
4. Create a new branch for your feature or bug fix
5. Make your changes
6. Run tests to ensure your changes work as expected
7. Submit a pull request

## Development Environment Setup

1. Install Flutter (version 3.7.2 or later) from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Set up your preferred IDE (VS Code, Android Studio, etc.)
3. Install the Flutter and Dart plugins for your IDE
4. Clone the repository and run `flutter pub get` to install dependencies
5. Run `flutter doctor` to ensure your environment is properly configured

## Project Structure

DevKick follows a clean architecture with a feature-first approach:

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

When working on a feature:
1. Determine if it belongs to an existing feature or requires a new feature directory
2. Keep all related code within the feature directory (presentation, domain, and data layers)
3. Use core components for shared functionality

## Core Models and Services

### Models

- **Command**: Represents a terminal command with properties like ID, label, command text, category, icon, and terminal type.
- **CommandSession**: Represents an active command execution session with properties for tracking state and output.
- **Routine**: Represents a group of commands that can be executed together.
- **ProcessResult**: Represents the result of executing a command.

### Services

- **CommandService**: Manages commands and their execution.
- **RoutineService**: Manages routines and their execution.
- **SettingsService**: Manages application settings.
- **BackupService**: Handles backup and restore of user data.
- **ToastService**: Provides toast notifications throughout the app.

## Coding Guidelines

1. **Naming Conventions**
   - Use `camelCase` for variables and methods
   - Use `PascalCase` for classes and types
   - Use descriptive names that convey purpose

2. **Code Style**
   - Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
   - Format code with `flutter format .` or use IDE formatting
   - Strive for a maximum line length of 80 characters

3. **Documentation**
   - Document all public APIs with dartdoc comments
   - Include examples for complex functionality
   - Keep comments up-to-date with code changes

4. **Error Handling**
   - Properly catch and handle exceptions
   - Provide meaningful error messages
   - Log errors when appropriate

5. **State Management**
   - Use a consistent approach to state management
   - Keep stateful widgets focused on a single responsibility
   - Consider extracting complex logic into separate classes

## Submitting Changes

1. Ensure your code builds and runs without errors
2. Write tests for new functionality
3. Run existing tests to verify your changes don't break anything
4. Update documentation as needed
5. Create a pull request with a clear description of your changes

## Pull Request Process

1. Create a pull request against the `main` branch
2. Fill out the pull request template with details about your changes
3. Link any relevant issues in your pull request description
4. Wait for a review from a maintainer
5. Address any feedback and make requested changes
6. Once approved, a maintainer will merge your pull request

## Issue Reporting

When reporting an issue, please include:

1. A clear and descriptive title
2. Steps to reproduce the issue
3. Expected behavior
4. Actual behavior
5. Screenshots if applicable
6. Environment information (OS, Flutter version, etc.)
7. Any additional context that might be helpful

---

Thank you for contributing to DevKick! Your efforts help make this project better for everyone. 