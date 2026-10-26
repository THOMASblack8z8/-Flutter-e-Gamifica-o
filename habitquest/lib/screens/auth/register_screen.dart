import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_error_banner.dart';
import 'auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final needsConfirmation = await _authService.signUp(
        displayName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Sem confirmação de e-mail, o Supabase já cria a sessão e o GoRouter
      // leva o usuário para a Home automaticamente.
      if (needsConfirmation && mounted) await _showConfirmEmailDialog();
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showConfirmEmailDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_rounded, color: AppColors.lilac, size: 40),
        title: const Text('Confirme seu e-mail'),
        content: Text(
          'Enviamos um link de confirmação para ${_emailController.text.trim()}. '
          'Abra o e-mail, confirme o cadastro e depois faça login.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Ir para o login'),
          ),
        ],
      ),
    );
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Crie seu herói',
      subtitle: 'Cadastre-se e transforme hábitos em conquistas.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.nickname],
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Nome de exibição',
                  helperText: 'Aparece no ranking. Não use dados pessoais.',
                  prefixIcon: Icon(Icons.badge_outlined),
                  counterText: '',
                ),
                validator: Validators.displayName,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Senha',
                  helperText: 'Mínimo de 6 caracteres.',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                    icon: Icon(_obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Confirme sua senha.';
                  if (value != _passwordController.text) return 'As senhas não coincidem.';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              if (_error != null) ...[
                FormErrorBanner(message: _error!),
                const SizedBox(height: 14),
              ],
              AppButton(
                label: 'Criar conta',
                icon: Icons.person_add_alt_1_rounded,
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Já tem conta?', style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: _loading ? null : () => context.go(AppRoutes.login),
                    child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
