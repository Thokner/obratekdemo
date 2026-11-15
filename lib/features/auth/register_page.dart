import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/data/repository.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';

class RegisterPage extends StatefulWidget {
  final ObratekRepository repository;
  const RegisterPage({super.key, required this.repository});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final repeat = TextEditingController();
  bool busy = false;
  bool obscure = true;

  Future<void> register() async {
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    try {
      await widget.repository.registerClient(name.text.trim(), email.text.trim(),
          password.text, phone.text.trim());
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Solicitud de acceso recibida'),
        content: const Text('Tu cuenta de cliente quedó pendiente. Un administrador de Obratek deberá aprobarla y asignarte tus construcciones.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Entendido'))],
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [name, email, phone, password, repeat]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crear cuenta de cliente')),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 530),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Tu espacio en Obratek', style: TextStyle(fontSize: 29,
            fontWeight: FontWeight.w800, color: AppPalette.ink)),
          const SizedBox(height: 9),
          const Text('Regístrate para consultar las obras que te asigne el equipo y enviar solicitudes directamente.',
            style: TextStyle(color: AppPalette.muted, height: 1.5)),
          const SizedBox(height: 22),
          SectionSurface(child: Form(key: form, child: Column(children: [
            TextFormField(controller: name, textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre y apellido *',
                prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: (v) => (v?.trim().length ?? 0) < 3 ? 'Escribe tu nombre' : null),
            const SizedBox(height: 14),
            TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Correo electrónico *',
                prefixIcon: Icon(Icons.alternate_email_rounded)),
              validator: (v) => v == null || !v.contains('@') ? 'Ingresa un correo válido' : null),
            const SizedBox(height: 14),
            TextFormField(controller: phone, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono (opcional)',
                prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 14),
            TextFormField(controller: password, obscureText: obscure,
              decoration: InputDecoration(labelText: 'Contraseña *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(tooltip: 'Mostrar u ocultar contraseña',
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
              validator: (v) => (v?.length ?? 0) < 12 ? 'Mínimo 12 caracteres' : null),
            const SizedBox(height: 14),
            TextFormField(controller: repeat, obscureText: obscure,
              decoration: const InputDecoration(labelText: 'Confirmar contraseña *',
                prefixIcon: Icon(Icons.verified_user_outlined)),
              validator: (v) => v != password.text ? 'Las contraseñas no coinciden' : null),
            const SizedBox(height: 19),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: busy ? null : register,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(busy ? 'Registrando...' : 'Solicitar acceso'))),
            const SizedBox(height: 14),
            const Text('Por seguridad, el registro no da acceso automático a ninguna obra. Obratek revisará y aprobará tu cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppPalette.muted, height: 1.5)),
          ]))),
          if (AppConfig.demoMode) const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Text('DEMO: no se enviarán correos ni se creará una cuenta real.',
              style: TextStyle(color: AppPalette.teal, fontSize: 12))),
        ])),
    ))),
  );
}
