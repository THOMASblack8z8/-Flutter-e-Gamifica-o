import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitquest/core/theme/app_theme.dart';
import 'package:habitquest/models/mission.dart';
import 'package:habitquest/models/user_mission.dart';
import 'package:habitquest/widgets/achievement_badge.dart';
import 'package:habitquest/widgets/mission_card.dart';
import 'package:habitquest/widgets/xp_progress_bar.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

final _mission = Mission(
  id: 'm1',
  title: 'Organizar as tarefas do dia',
  description: 'Liste as tarefas do dia e defina prioridades.',
  rules: 'Escreva a lista.',
  category: 'organizacao',
  xpReward: 25,
  coinReward: 2,
  difficulty: 'facil',
  isActive: true,
  createdAt: DateTime(2026, 10, 26),
);

void main() {
  testWidgets('MissionCard exibe título, XP, status e responde ao toque', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      MissionCard(mission: _mission, status: MissionStatus.available, onTap: () => tapped = true),
    ));

    expect(find.text('Organizar as tarefas do dia'), findsOneWidget);
    expect(find.text('+25'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
    expect(find.text('Organização'), findsOneWidget);

    await tester.tap(find.byType(MissionCard));
    expect(tapped, isTrue);
  });

  testWidgets('MissionCard mostra status concluída', (tester) async {
    await tester.pumpWidget(_wrap(MissionCard(mission: _mission, status: MissionStatus.completed)));
    expect(find.text('Concluída'), findsOneWidget);
  });

  testWidgets('XpProgressBar mostra nível, XP e quanto falta', (tester) async {
    await tester.pumpWidget(_wrap(const XpProgressBar(level: 3, currentXp: 50, requiredXp: 300)));
    await tester.pumpAndSettle();

    expect(find.text('Nível 3'), findsOneWidget);
    expect(find.text('50 / 300 XP'), findsOneWidget);
    expect(find.text('Faltam 250 XP para o nível 4'), findsOneWidget);
  });

  testWidgets('AchievementBadge diferencia bloqueada e desbloqueada', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox(
      width: 200,
      height: 240,
      child: AchievementBadge(
        name: 'Consistência',
        description: 'Conclua cinco missões.',
        iconKey: 'repeat',
        unlocked: false,
        criteria: 'Concluir 5 missões',
      ),
    )));
    expect(find.text('Consistência'), findsOneWidget);
    expect(find.text('Concluir 5 missões'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

    await tester.pumpWidget(_wrap(SizedBox(
      width: 200,
      height: 240,
      child: AchievementBadge(
        name: 'Consistência',
        description: 'Conclua cinco missões.',
        iconKey: 'repeat',
        unlocked: true,
        unlockedAt: DateTime(2026, 10, 26),
      ),
    )));
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.text('Desbloqueada em 26/10/2026'), findsOneWidget);
  });
}
