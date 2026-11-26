import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'auth_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _createAccount = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit(AuthViewModel vm) {
    FocusScope.of(context).unfocus();
    _createAccount
        ? vm.signUp(_email.text, _password.text)
        : vm.signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.menu_book,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Minhas Receitas',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _createAccount
                      ? 'Crie sua conta'
                      : 'Entre para ver seu caderno',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('email_field'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('password_field'),
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(vm),
                ),
                if (vm.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    vm.error!,
                    key: const Key('auth_error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('auth_submit'),
                  onPressed: vm.busy ? null : () => _submit(vm),
                  child: vm.busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_createAccount ? 'Criar conta' : 'Entrar'),
                ),
                TextButton(
                  key: const Key('auth_toggle'),
                  onPressed: vm.busy
                      ? null
                      : () => setState(() => _createAccount = !_createAccount),
                  child: Text(
                    _createAccount ? 'Já tenho conta' : 'Criar uma conta',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
