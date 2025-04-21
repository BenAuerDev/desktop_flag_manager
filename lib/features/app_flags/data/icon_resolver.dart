import 'dart:io';
import 'package:path/path.dart' as p;

class IconResolver {
  final Map<String, String?> _iconPathCache = {};

  void clearCache() {
    _iconPathCache.clear();
  }

  Future<String?> resolveIconPath(String iconNameOrPath) async {
    // Check cache first
    if (_iconPathCache.containsKey(iconNameOrPath)) {
      return _iconPathCache[iconNameOrPath];
    }

    // 1. Check absolute path
    if (p.isAbsolute(iconNameOrPath)) {
      final file = File(iconNameOrPath);
      try {
        if (await file.exists()) {
          _iconPathCache[iconNameOrPath] = iconNameOrPath; // Cache
          return iconNameOrPath;
        }
      } catch (_) {}
      // Absolute path specified but not found
      _iconPathCache[iconNameOrPath] = null; // Cache null
      return null;
    }

    // 2. Simplified Name Lookup
    final String iconName = p.basenameWithoutExtension(iconNameOrPath);
    String? foundPath;

    String? userIconDir;
    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null && homeDir.isNotEmpty) {
        userIconDir = p.join(homeDir, '.local', 'share', 'icons');
      }
    } catch (_) {}

    // Simplified list of base directories
    final List<String> baseDirs = [
      if (userIconDir != null) userIconDir,
      '/usr/share/icons/hicolor', // Standard fallback
      '/usr/share/pixmaps', // Legacy
      '/usr/share/icons/Adwaita', // Common GTK theme
    ];

    // Simplified search parameters
    final List<String> sizes = ['scalable', '64x64', '48x48', ''];
    final List<String> extensions = ['.png', '.svg', ''];
    final List<String> subDirsToCheck = [
      'apps',
      ''
    ]; // Only check 'apps' and root

    outerLoop: // Label to break out early
    for (final baseDir in baseDirs) {
      try {
        // Skip check if dir doesn't exist - reduces async calls slightly
        if (!await Directory(baseDir).exists()) continue;
      } catch (_) {
        continue;
      }

      if (p.basename(baseDir) == 'pixmaps') {
        for (final ext in extensions) {
          final path = p.join(baseDir, '$iconName$ext');
          try {
            if (await File(path).exists()) {
              foundPath = path;
              break outerLoop;
            }
          } catch (_) {}
        }
      } else {
        for (final size in sizes) {
          for (final subDir in subDirsToCheck) {
            for (final ext in extensions) {
              final pathSegments = [baseDir];
              if (size.isNotEmpty) pathSegments.add(size);
              if (subDir.isNotEmpty) pathSegments.add(subDir);
              final path = p.joinAll([...pathSegments, '$iconName$ext']);
              try {
                if (await File(path).exists()) {
                  foundPath = path;
                  break outerLoop; // Found it, stop searching
                }
              } catch (_) {}
            }
          }
        }
      }
    }

    _iconPathCache[iconNameOrPath] = foundPath; // Cache result
    return foundPath;
  }
}
