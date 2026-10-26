import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, danger }

/// Botão padrão do app. Mostra um indicador e fica desabilitado
/// enquanto [loading] é verdadeiro (evita cliques repetidos).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final isPrimary = variant == AppButtonVariant.primary;
    final borderColor = switch (variant) {
      AppButtonVariant.danger => AppColors.error,
      _ => AppColors.lilac,
    };

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: isPrimary ? AppColors.primaryGradient : null,
          color: isPrimary ? null : AppColors.surfaceAlt.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: borderColor.withValues(alpha: 0.6)),
          boxShadow: isPrimary && enabled
              ? [BoxShadow(color: AppColors.violet.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 6))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: isPrimary ? Colors.white : borderColor, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isPrimary ? Colors.white : borderColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
