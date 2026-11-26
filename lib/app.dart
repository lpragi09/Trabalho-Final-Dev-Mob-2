import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'app_dependencies.dart';
import 'ui/auth/auth_viewmodel.dart';
import 'ui/auth/login_view.dart';
import 'ui/common/state_views.dart';
import 'ui/home/home_view.dart';

class MinhasReceitasApp extends StatelessWidget {
  const MinhasReceitasApp({super.key, required this.deps});
  final AppDependencies deps;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: deps),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(deps.authRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Minhas Receitas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFFD9480F),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Controla o acesso: sem sessão mostra o login; com sessão, a área protegida.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (!auth.ready) return const Scaffold(body: LoadingView());
    final user = auth.user;
    if (user == null) return const LoginView();
    // A key por UID recria os ViewModels ao trocar de conta.
    return HomeView(key: ValueKey(user.uid), uid: user.uid, email: user.email);
  }
}
