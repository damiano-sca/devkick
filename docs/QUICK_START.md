# DevKick Quick Start Guide

This guide will help you get started with DevKick, a powerful tool for managing and executing terminal commands.

## Installation

1. Download the latest release for your platform from the [Releases page](https://github.com/yourusername/devkick/releases)
2. Install the application:
   - **Windows**: Run the installer (.exe)
   - **macOS**: Drag the .app file to your Applications folder
   - **Linux**: Extract the archive and run the executable

## Initial Setup

When you first launch DevKick, you'll be asked to configure your terminal paths. The application will attempt to detect these automatically, but you can adjust them if needed.

## Creating Your First Command

1. Click on the **Commands** tab in the navigation rail (left side)
2. Click the **+** floating action button in the bottom right
3. Fill in the command details:
   - **Label**: A descriptive name for your command
   - **Command**: The actual terminal command to run
   - **Category**: The category to group this command under
   - **Icon**: Choose an icon to visually identify the command
   - **Terminal Type**: Select the appropriate terminal (Command Prompt, Bash, PowerShell)
4. Click **Save**

![Add Command Screenshot](add_command_screenshot.png)

## Running a Command

1. From the Commands list, find the command you want to run
2. Click the **Run** button (play icon)
3. The command will execute and a new tab will appear in the navigation rail
4. You'll see the command output in real-time

## Creating a Routine

Routines allow you to group multiple commands to run in sequence or parallel.

1. Click on the **Routines** tab in the navigation rail
2. Click the **+** floating action button
3. Fill in the routine details:
   - **Name**: A descriptive name for your routine
   - **Description**: Optional description of what the routine does
   - **Icon**: Choose an icon for this routine
   - **Run in Parallel**: Toggle on if you want commands to run simultaneously
4. Add commands to the routine:
   - Click **Add Command**
   - Select commands from your saved commands
   - Use drag handles to reorder commands if running sequentially
5. Click **Save**

## Tips and Tricks

- **Terminal Sessions**: You can have multiple terminal sessions open at once
- **Navigation**: Use the rail on the left to switch between commands, routines, and active terminals
- **Command Reuse**: The same command can be used in multiple routines
- **Categories**: Use categories to organize your commands by project, technology, or purpose
- **Settings**: Access application settings via the gear icon at the bottom of the navigation rail

## Backup and Restore

DevKick allows you to export your commands and routines for backup or transfer to another computer.

1. Go to **Settings**
2. Click **Backup & Restore**
3. To backup: Click **Export** and choose where to save your backup file
4. To restore: Click **Import** and select a previously exported file

## Troubleshooting

- **Command not found**: Ensure the command exists in the selected terminal type
- **Permission issues**: Some commands might require elevated privileges
- **Terminal path incorrect**: You can update terminal paths in Settings

## Getting Help

If you encounter any issues or have questions:

- Check the [FAQ](FAQ.md)
- Search or open issues on [GitHub](https://github.com/yourusername/devkick/issues)
- Read the [full documentation](https://github.com/yourusername/devkick/docs) 