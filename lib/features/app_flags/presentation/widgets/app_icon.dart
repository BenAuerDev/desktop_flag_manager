part of 'app_list_item.dart';

class _AppIcon extends ConsumerWidget {
  final String iconNameOrPath;

  const _AppIcon({required this.iconNameOrPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconPathAsyncValue = ref.watch(iconPathProvider(iconNameOrPath));

    return iconPathAsyncValue.when(
      data: (iconPath) {
        if (iconPath != null) {
          final iconFile = File(iconPath);
          final isSvg = p.extension(iconPath).toLowerCase() == '.svg';
          return SizedBox(
            width: 40,
            height: 40,
            child: isSvg
                ? SvgPicture.file(
                    iconFile,
                    placeholderBuilder: (context) =>
                        const Icon(Icons.image_search, size: 32),
                  )
                : Image.file(
                    iconFile,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 32);
                    },
                  ),
          );
        } else {
          return const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.image_not_supported_outlined, size: 32),
          );
        }
      },
      loading: () => const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 2.0)),
      error: (error, stack) => const SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          Icons.error_outline,
          size: 32,
          color: Colors.red,
        ),
      ),
    );
  }
}
