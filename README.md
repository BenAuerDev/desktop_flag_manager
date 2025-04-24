# Desktop Flag Manager

A Flutter application for managing launch flags and environment variables for Linux desktop applications. This tool helps you create and manage local overrides of `.desktop` files to customize application behavior.

![screenshot_21042025_162221](https://github.com/user-attachments/assets/cde094bc-3ac2-4a02-a914-3d554eeffb73)
![screenshot_21042025_162308](https://github.com/user-attachments/assets/152059eb-bd73-458c-9725-c1d7a129ce5c)

## Features

- **Easy Flag Management**: Toggle common flags and environment variables with a simple switch interface
- **Local Overrides**: Create and manage local copies of desktop entries without modifying system files
- **Search & Filter**: Quickly find applications and filter by local/system entries
- **Icon Support**: View application icons with automatic resolution
- **Database Updates**: Automatic desktop database updates after changes

## Supported Flags & Variables

- **OZONE_PLATFORM**: Control the platform backend (x11, wayland)
- **DISABLE_GPU**: Disable GPU acceleration
- **ENABLE_OZONE_PLATFORM_HINT**: Enable platform-specific hints
- **CHROME_DESKTOP**: Set Chrome desktop environment

## Installation

### AppImage from Release (Recommended)

1. **Download:** Go to the **[Latest Release page](https://github.com/BenAuerDev/desktop_flag_manager/releases/latest)** and download the `.AppImage` file from the "Assets" section.
2. **Make Executable:** Open your terminal, navigate to the directory where you downloaded the file (e.g., `cd ~/Downloads`), and run:

    ```bash
    chmod +x Desktop_Flag_Manager-*.AppImage
    ```

    (Replace `*` with the specific version/build identifier in the filename).
3. **Run:** You can now run the application directly:

    ```bash
    ./Desktop_Flag_Manager-*.AppImage
    ```

4. **Integration (Optional but Recommended):** To add the application to your system's menu for easy launching:
    - **Gear Lever (Recommended):** A great tool for managing and integrating AppImages (often available via Flathub). Use Gear Lever to add the downloaded AppImage.
    - **AppImageLauncher:** Another popular tool that prompts for integration when you first run an AppImage.
    - **Manual:** You can move the AppImage to a location like `~/Applications` and create a `.desktop` file in `~/.local/share/applications/` pointing to it.

### From Source (for Development)

1. Ensure you have Flutter installed (stable channel recommended).
2. Clone this repository: `git clone https://github.com/BenAuerDev/desktop_flag_manager.git`
3. Navigate into the directory: `cd desktop_flag_manager`
4. Get dependencies: `flutter pub get`
5. Build and run: `flutter run`

## Usage

1. Launch the application
2. Search for the application you want to modify
3. Click on the application to expand its options
4. Toggle the desired flags or variables
5. The changes will be applied automatically

## Common Use Cases

### Fixing Wayland Issues

If an application doesn't work well under Wayland:

1. Find the application in the list
2. Enable `OZONE_PLATFORM=x11`
3. This forces the application to use X11 backend

### Reducing GPU Usage

For applications with high GPU usage:

1. Find the application in the list
2. Enable `DISABLE_GPU=1`
3. This disables GPU acceleration

## Troubleshooting

### Application Not Found

- Ensure the application is installed in a standard location
- Check if the application has a valid `.desktop` file

### Changes Not Taking Effect

- Try running `update-desktop-database` manually
- Check if the application is running (changes only affect new instances)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License

## Acknowledgments

- Flutter for the UI framework
- Linux desktop standards for `.desktop` file format
