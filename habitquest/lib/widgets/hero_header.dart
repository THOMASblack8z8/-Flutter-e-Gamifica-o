import 'package:flutter/material.dart';

import '../core/constants/hero_classes.dart';
import '../core/theme/app_colors.dart';
import '../models/profile.dart';
import 'hero_avatar.dart';
import 'xp_progress_bar.dart';

/// Painel do herói: avatar, saudação, classe, moedas e barra de XP.
class HeroHeader extends StatelessWidget {
  const HeroHeader({super.key, required this.profile, this.onAvatarTap});

  final Profile profile;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final heroClass = HeroClasses.of(profile.heroClass);
    final progress = profile.progress;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lilac.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: AppColors.violet.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: HeroAvatar(
                  heroClass: profile.heroClass,
                  level: profile.level,
                  avatarUrl: profile.avatarUrl,
                  size: 92,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Olá,', style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(heroClass.icon, size: 16, color: heroClass.color),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${heroClass.label} · Nível ${profile.level}',
                            style: const TextStyle(color: AppColors.lilac, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.paid_rounded, size: 16, color: AppColors.gold),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.coins} moedas',
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          XpProgressBar(
            level: profile.level,
            currentXp: progress.xpIntoLevel,
            requiredXp: progress.xpForThisLevel,
          ),
        ],
      ),
    );
  }
}
