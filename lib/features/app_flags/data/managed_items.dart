// Define enum for managed item type
enum ManagedItemType { flag, environmentVariable }

// Define class to hold managed item details
class ManagedItem {
  final String identifier;
  final ManagedItemType type;
  final String description;
  final String? value; // Only used for environment variables, e.g., "x11"

  const ManagedItem({
    required this.identifier,
    required this.type,
    required this.description,
    this.value,
  });

  String get fullString {
    if (type == ManagedItemType.environmentVariable && value != null) {
      return '$identifier=$value';
    }
    return identifier;
  }
}

class ManagedItems {
  static final List<ManagedItem> items = [
    const ManagedItem(
      identifier: '--disable-gpu',
      type: ManagedItemType.flag,
      description:
          'Disables hardware acceleration. Fixes crashes, flickering, or rendering artifacts, especially with NVIDIA GPUs or buggy drivers. May reduce performance.',
    ),
    const ManagedItem(
      identifier: '--ozone-platform=x11',
      type: ManagedItemType.flag,
      description:
          'Forces the application to run using XWayland. Useful if native Wayland support is broken or unstable for the app, but may cause blurriness on HiDPI displays.',
    ),
    const ManagedItem(
      identifier: '--ozone-platform=wayland',
      type: ManagedItemType.flag,
      description:
          'Forces the application to attempt using native Wayland rendering. Can fix blurriness on HiDPI displays if the app supports it well.',
    ),
    const ManagedItem(
      identifier: '--ozone-platform-hint=auto',
      type: ManagedItemType.flag,
      description:
          'Allows the application to auto-detect whether to use Wayland or X11 based on the current session.',
    ),
    const ManagedItem(
      identifier: '--enable-features=UseOzonePlatform,WaylandWindowDecorations',
      type: ManagedItemType.flag,
      description:
          'Enables specific Chromium features for Wayland, including native window decorations. Often needed for a complete native Wayland experience (crisp text, proper borders).',
    ),
    const ManagedItem(
      identifier: 'ELECTRON_OZONE_PLATFORM_HINT',
      type: ManagedItemType.environmentVariable,
      value: 'x11',
      description:
          'Forces the application to run using XWayland (alternative method). Useful if native Wayland support is broken or unstable. Requires prepending \'env VAR=value\' to the command.',
    ),
  ];
}
