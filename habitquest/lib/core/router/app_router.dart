import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/achievements/achievements_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/missions/mission_detail_screen.dart';
import '../../screens/missions/missions_screen.dart';
import '../../screens/not_found_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/ranking/ranking_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../widgets/main_shell.dart';
import 'auth_notifier.dart';

/// Caminhos de todas as rotas do aplicativo.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const missions = '/missions';
  static const achievements = '/achievements';
  static const ranking = '/ranking';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';

  /// Detalhes recebem o id da missão como parâmetro: /missions/:id
  static String missionDetails(String id) => '/missions/$id';

  static const publicRoutes = {login, register};
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthNotifier auth) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    // Sempre que o usuário entrar/sair, o redirect é reavaliado.
    refreshListenable: auth,
    redirect: (context, state) => _guard(auth, state),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Área interna com barra de navegação inferior.
      // Cada aba mantém o próprio estado (indexedStack).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.missions, builder: (context, state) => const MissionsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.achievements,
              builder: (context, state) => const AchievementsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.ranking, builder: (context, state) => const RankingScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),

      // Telas internas em tela cheia (abertas com context.push).
      GoRoute(
        path: '/missions/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MissionDetailScreen(missionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
}

/// Proteção de rotas.
///  * Antes da verificação da sessão: permanece na Splash.
///  * Não autenticado tentando abrir rota interna: vai para o Login.
///  * Autenticado tentando abrir Login/Cadastro: vai para a Home.
/// A segurança dos DADOS é garantida pelo RLS no banco, não por esta função.
String? _guard(AuthNotifier auth, GoRouterState state) {
  final location = state.matchedLocation;
  final onSplash = location == AppRoutes.splash;
  final onPublicRoute = AppRoutes.publicRoutes.contains(location);

  if (!auth.startupDone) return onSplash ? null : AppRoutes.splash;

  if (!auth.isLoggedIn) {
    return onPublicRoute ? null : AppRoutes.login;
  }

  if (onSplash || onPublicRoute) return AppRoutes.home;
  return null;
}
