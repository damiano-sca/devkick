# DevKick

A modern Flutter desktop application with Material 3 design for Windows.

## Features

- Clean and modern Material 3 UI design
- Dark/Light theme support
- Dashboard view with development statistics
- Projects view (coming soon)
- Settings view (coming soon)

## Getting Started

### Prerequisites

- Flutter SDK (3.x or later)
- Windows development environment

### Installation

1. Clone the repository:
```
git clone https://github.com/yourusername/devkick.git
```

2. Navigate to the project directory:
```
cd devkick
```

3. Install dependencies:
```
flutter pub get
```

4. Run the app:
```
flutter run -d windows
```

## Project Structure

The project follows a clean architecture approach:

```
lib/
  core/
    constants/      # Application constants
    theme/          # Theme configuration
    utils/          # Utility functions
    widgets/        # Reusable widgets
  features/
    home/
      presentation/
        pages/      # Home screen pages
        widgets/    # Feature-specific widgets
  main.dart         # Entry point
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
