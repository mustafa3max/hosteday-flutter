import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Modern responsive card displaying a categorized code sample with a one-tap copy button.
class CodeSnippetCard extends StatelessWidget {
  final String title;
  final String description;
  final String code;
  final String language;
  final String? category;
  final IconData? icon;
  final ValueNotifier<bool> _copiedNotifier = ValueNotifier<bool>(false);

  CodeSnippetCard({
    required this.title,
    required this.description,
    required this.code,
    this.language = 'dart',
    this.category,
    this.icon,
    super.key,
  });

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    _copiedNotifier.value = true;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('code_copied'.tr),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Future<void>.delayed(const Duration(seconds: 2), () {
      _copiedNotifier.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Top Bar: Category badge + Language + Copy Action
              Row(
                children: <Widget>[
                  if (category != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (icon != null) ...<Widget>[
                            Icon(
                              icon,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            category!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      language.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<bool>(
                    valueListenable: _copiedNotifier,
                    builder: (context, copied, _) {
                      return FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 32),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _copyCode(context),
                        icon: Icon(
                          copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 14,
                          color: copied ? Colors.greenAccent : null,
                        ),
                        label: Text(copied ? 'copied'.tr : 'copy'.tr),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Card Title
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Code Display Area
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF141419),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Terminal Header
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          color: const Color(0xFF1C1C22),
                          child: Row(
                            children: <Widget>[
                              _buildCircleIndicator(const Color(0xFFFF5F56)),
                              const SizedBox(width: 6),
                              _buildCircleIndicator(const Color(0xFFFFBD2E)),
                              const SizedBox(width: 6),
                              _buildCircleIndicator(const Color(0xFF27C93F)),
                              const SizedBox(width: 12),
                              Text(
                                language == 'bash'
                                    ? 'terminal'
                                    : 'snippet.dart',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Color(0xFF888899),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Terminal Body
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(14),
                          child: SelectableText(
                            code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              height: 1.55,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIndicator(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
