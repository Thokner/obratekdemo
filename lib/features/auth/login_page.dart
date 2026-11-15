import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final ObratekRepository repository;
  final ValueChanged<UserSession> onAuthenticated;
  const LoginPage({super.key, required this.repository,
      required this.onAuthenticated});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool visible = false;

  Future<void> submit({bool asDemoClient = false, bool demoPending = false,
    bool demoPlus = false, bool demoFree = false}) async {
    if (!AppConfig.demoMode && !(formKey.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    try {
      final user = await widget.repository.login(
        AppConfig.demoMode ? (demoPending ? 'pendiente@demo.local' :
          demoPlus ? 'plus@demo.local' : demoFree ? 'gratis@demo.local' :
          asDemoClient ? 'cliente@demo.local' : 'admin@demo.local') : email.text.trim(),
        password.text);
      if (mounted) widget.onAuthenticated(user);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 920;
      return Row(children: [
        if (wide) const Expanded(flex: 5, child: _BrandWelcome()),
        Expanded(flex: 6, child: SafeArea(child: Center(
          child: SingleChildScrollView(padding: const EdgeInsets.all(25),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!wide) ...[
                    Center(child: Image.asset('assets/brand/obratek_marca.png',
                      height: 77, fit: BoxFit.contain)),
                    const SizedBox(height: 15),
                  ],
                  Text('Bienvenido a Obratek',
                    style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 9),
                  const Text('Accede a tu espacio de trabajo o al portal de tus construcciones.',
                    style: TextStyle(color: AppPalette.muted, height: 1.5)),
                  const SizedBox(height: 23),
                  SectionSurface(padding: const EdgeInsets.all(25), child: Form(
                    key: formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Acceder a mi cuenta',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 19),
                      TextFormField(controller: email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.mail_outline_rounded)),
                        validator: (v) => v == null || !v.contains('@')
                          ? 'Ingresa un correo válido' : null),
                      const SizedBox(height: 14),
                      TextFormField(controller: password, obscureText: !visible,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => visible = !visible),
                            icon: Icon(visible ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined))),
                        validator: (v) => v == null || v.isEmpty
                          ? 'Ingresa tu contraseña' : null),
                      const SizedBox(height: 20),
                      FilledButton.icon(onPressed: busy ? null : () => submit(),
                        icon: busy ? const SizedBox(width: 17, height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2,
                            color: Colors.white))
                          : const Icon(Icons.arrow_forward_rounded),
                        label: Text(AppConfig.demoMode
                          ? 'Entrar como administrador (DEMO)' : 'Iniciar sesión')),
                      if (AppConfig.demoMode) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => submit(asDemoClient: true),
                          icon: const Icon(Icons.account_circle_outlined),
                          label: const Text('Cliente Suscrito (DEMO)')),
                        const SizedBox(height: 7),
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => submit(demoPlus: true),
                          icon: const Icon(Icons.workspace_premium_outlined),
                          label: const Text('Cliente Plus (DEMO)')),
                        const SizedBox(height: 7),
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => submit(demoFree: true),
                          icon: const Icon(Icons.person_outline),
                          label: const Text('Cliente No suscrito (DEMO)')),
                        TextButton(onPressed: busy ? null : () => submit(demoPending: true),
                          child: const Text('Ver cliente pendiente de aprobación')),
                        const SizedBox(height: 5),
                        const Text('DEMO · Datos ficticios. No se guardan en el servidor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppPalette.teal, fontSize: 11)),
                      ],
                      const SizedBox(height: 9),
                      TextButton.icon(onPressed: busy ? null : () async {
                        final registered = await Navigator.push<bool>(context,
                          MaterialPageRoute(builder: (_) => RegisterPage(
                            repository: widget.repository)));
                        if (registered == true && context.mounted) {
                          showSnack(context,
                            'Cuenta registrada. Inicia sesión para consultar su aprobación.');
                        }
                      }, icon: const Icon(Icons.person_add_alt_outlined),
                        label: const Text('Soy cliente · Crear mi cuenta')),
                    ]))),
                  const SizedBox(height: 18),
                  const Center(child: Text('OBRATEK 0.0.004 · VERSIÓN DE DESARROLLO',
                    style: TextStyle(color: AppPalette.muted,
                      fontSize: 10, letterSpacing: 0.9))),
                ]),
            ),
          ),
        ))),
      ]);
    }),
  );
}

class _BrandWelcome extends StatelessWidget {
  const _BrandWelcome();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [AppPalette.navyDark, AppPalette.navy, Color(0xFF1B3155)])),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 57, vertical: 36),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Image.asset('assets/brand/obratek_marca_oscura.png', width: 59, height: 59),
          const SizedBox(width: 12),
          const Text('Obratek', style: TextStyle(fontSize: 29,
            fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(width: 9),
          const Text('0.0.004', style: TextStyle(color: AppPalette.cyan,
            fontWeight: FontWeight.w800)),
        ]),
        const Spacer(),
        const Text('Tu construcción,\nmejor conectada.',
          style: TextStyle(color: Colors.white, fontSize: 40,
            height: 1.16, fontWeight: FontWeight.w900, letterSpacing: -1.3)),
        const SizedBox(height: 20),
        const Text('Un solo lugar para coordinar obras, órdenes de trabajo, avances y solicitudes de clientes.',
          style: TextStyle(color: Color(0xFFD1DEEE), fontSize: 15, height: 1.6)),
        const SizedBox(height: 27),
        const _BrandFeature(Icons.shield_outlined, 'Accesos según tu perfil'),
        const SizedBox(height: 13),
        const _BrandFeature(Icons.apartment_outlined, 'Seguimiento de construcciones'),
        const SizedBox(height: 13),
        const _BrandFeature(Icons.auto_graph_outlined, 'Información clara y centralizada'),
        const Spacer(),
        Container(width: 114, height: 6, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors: [AppPalette.primary, AppPalette.cyan]))),
      ]),
    ),
  );
}

class _BrandFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  const _BrandFeature(this.icon, this.title);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppPalette.cyan, size: 22),
    const SizedBox(width: 12),
    Expanded(child: Text(title, style: const TextStyle(
      color: Colors.white, fontWeight: FontWeight.w600))),
  ]);
}
