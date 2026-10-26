import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/hero_classes.dart';
import '../../core/router/app_router.dart';
import '../../core/state/progress_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/validators.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_error_banner.dart';
import '../../widgets/hero_avatar.dart';
import '../../widgets/state_views.dart';

/// Edição das informações básicas: nome, classe do herói e imagem.
/// XP, nível e moedas não podem ser editados (o banco bloqueia).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _avatarController = TextEditingController();

  Future<Profile>? _future;
  String _heroClass = HeroClasses.all.first.key;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _future = _profileService.getMyProfile().then((profile) {
        _nameController.text = profile.displayName;
        _avatarController.text = profile.avatarUrl ?? '';
        _heroClass = profile.heroClass;
        return profile;
      });
    });
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profile);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _profileService.updateProfile(
        displayName: _nameController.text,
        heroClass: _heroClass,
        avatarUrl: _avatarController.text,
      );
      ProgressNotifier.instance.changed();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
      _goBack();
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Editar perfil'),
          leading: IconButton(tooltip: 'Voltar', icon: const Icon(Icons.arrow_back_rounded), onPressed: _goBack),
        ),
        body: FutureContent<Profile>(
          future: _future,
          onRetry: _load,
          loadingMessage: 'Carregando perfil...',
          builder: (context, profile) => Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Center(
                  child: HeroAvatar(
                    heroClass: _heroClass,
                    level: profile.level,
                    avatarUrl: _avatarController.text.trim().isEmpty ? null : _avatarController.text.trim(),
                    size: 120,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome de exibição',
                    prefixIcon: Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                  validator: Validators.displayName,
                ),
                const SizedBox(height: 20),
                Text('Classe do herói', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // Altura fixa para não esticar no PC nem cortar no celular.
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 100,
                  ),
                  children: [
                    for (final heroClass in HeroClasses.all)
                      _HeroClassOption(
                        heroClass: heroClass,
                        selected: heroClass.key == _heroClass,
                        onTap: () => setState(() => _heroClass = heroClass.key),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _avatarController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Link de imagem (opcional)',
                    helperText: 'Deixe em branco para usar o herói ilustrado.',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                  validator: Validators.optionalUrl,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  FormErrorBanner(message: _error!),
                  const SizedBox(height: 14),
                ],
                AppButton(label: 'Salvar alterações', icon: Icons.save_rounded, loading: _saving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroClassOption extends StatelessWidget {
  const _HeroClassOption({required this.heroClass, required this.selected, required this.onTap});

  final HeroClass heroClass;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? heroClass.color.withValues(alpha: 0.2) : AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? heroClass.color : AppColors.border, width: selected ? 2 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(heroClass.icon, color: heroClass.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(heroClass.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    if (selected) Icon(Icons.check_circle_rounded, color: heroClass.color, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  heroClass.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
