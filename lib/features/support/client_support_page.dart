import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';
import 'support_widgets.dart';

class ClientSupportPage extends StatefulWidget {
  final ObratekRepository repository;
  final VoidCallback onGoToRequests;
  const ClientSupportPage({super.key, required this.repository,
    required this.onGoToRequests});
  @override
  State<ClientSupportPage> createState() => _ClientSupportPageState();
}

class _ClientSupportPageState extends State<ClientSupportPage> {
  SupportOverview? state;
  String? error;
  bool loading = true, sending = false;
  StreamSubscription<int>? live;
  Timer? poll;
  int? connectedThreadId;

  @override
  void initState() {
    super.initState();
    refresh(initial: true);
    // Respaldo de reconexión: también funciona si se corta el websocket.
    poll = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
  }

  Future<void> refresh({bool initial = false}) async {
    if (initial && mounted) setState(() => loading = true);
    try {
      var overview = await widget.repository.clientSupport();
      if (overview.enabled && overview.thread == null) {
        await widget.repository.openClientSupport();
        overview = await widget.repository.clientSupport();
      }
      if (!mounted) return;
      setState(() { state = overview; error = null; loading = false; });
      if (overview.enabled && overview.thread != null) {
        connect(overview.thread!.id);
      } else if (connectedThreadId != null) {
        await live?.cancel();
        connectedThreadId = null;
      }
    } catch (e) {
      if (mounted) setState(() { loading = false; error = '$e'; });
    }
  }

  void connect(int threadId) {
    if (AppConfig.demoMode || connectedThreadId == threadId) return;
    live?.cancel();
    connectedThreadId = threadId;
    live = widget.repository.supportEvents(threadId).listen((_) => refresh(),
      onError: (_) { connectedThreadId = null; });
  }

  Future<void> send(String body) async {
    setState(() => sending = true);
    try {
      await widget.repository.sendClientSupport(body);
      await refresh();
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    poll?.cancel();
    live?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageTitle(eyebrow: 'Estamos para ayudarte', title: 'Centro de soporte',
          subtitle: 'Conversa con nuestro equipo sin salir de Obratek.'),
        const SizedBox(height: 16),
        if (AppConfig.demoMode) const Padding(padding: EdgeInsets.only(bottom: 10),
          child: Text('DEMOSTRACIÓN · Los mensajes de prueba no se guardan en el servidor.',
            style: TextStyle(color: AppPalette.teal, fontSize: 11))),
        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (error != null)
          Expanded(child: Center(child: SectionSurface(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              Text('No se pudo conectar con soporte: $error', textAlign: TextAlign.center),
              const SizedBox(height: 15),
              OutlinedButton.icon(onPressed: () => refresh(initial: true),
                icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
            ]))))
        else if (state != null && !state!.enabled)
          Expanded(child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 690),
            child: SectionSurface(child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center, children: [
                const CircleAvatar(backgroundColor: AppPalette.primarySoft, radius: 32,
                  child: Icon(Icons.lock_outline_rounded, color: AppPalette.primary, size: 33)),
                const SizedBox(height: 15),
                const Text('El chat en vivo es para Suscritos y Plus',
                  textAlign: TextAlign.center, style: TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                const SupportPlanPill('no_suscrito'),
                const SizedBox(height: 14),
                const Text('Puedes seguir consultando tus construcciones y enviar solicitudes. '
                  'La administración de Obratek debe activar un plan para habilitar este chat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.6, color: AppPalette.muted)),
                const SizedBox(height: 19),
                FilledButton.icon(onPressed: widget.onGoToRequests,
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Ir a mis solicitudes')),
                if (state!.messages.isNotEmpty) ...[
                  const SizedBox(height: 17),
                  Text('Se conserva tu historial anterior (${state!.messages.length} mensajes).',
                    style: const TextStyle(color: AppPalette.muted, fontSize: 11)),
                ],
              ])))))
        else if (state?.thread != null)
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            final info = SectionSurface(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tu nivel de soporte',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 12),
                SupportPlanPill(state!.plan),
                const SizedBox(height: 15),
                Text(state!.plan == 'plus' ? 'Atención prioritaria en la bandeja de Obratek.'
                  : 'Chat directo con el equipo de soporte.',
                  style: const TextStyle(color: AppPalette.muted, height: 1.5)),
                const SizedBox(height: 20),
                const SoftDivider(),
                const SizedBox(height: 16),
                const Row(children: [
                  Icon(Icons.shield_outlined, color: AppPalette.teal, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Solo tú y el personal autorizado pueden acceder a este chat.',
                    style: TextStyle(fontSize: 12, height: 1.5))),
                ]),
                const SizedBox(height: 20),
                OutlinedButton.icon(onPressed: () => refresh(initial: true),
                  icon: const Icon(Icons.refresh), label: const Text('Actualizar mensajes')),
              ]));
            final chat = SupportChatWindow(
              title: 'Equipo de soporte Obratek',
              subtitle: state!.plan == 'plus' ? 'Canal Plus · Prioritario' : 'Canal Suscrito',
              status: state!.thread!.status, viewingAsClient: true,
              canSend: state!.thread!.status == 'abierta', isBusy: sending,
              messages: state!.messages, onSend: send);
            if (constraints.maxWidth >= 900) {
              return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(width: 270, child: SingleChildScrollView(child: info)),
                const SizedBox(width: 15), Expanded(child: chat),
              ]);
            }
            return Column(children: [
              SizedBox(height: 112, child: SectionSurface(child: Row(children: [
                SupportPlanPill(state!.plan), const SizedBox(width: 10),
                const Expanded(child: Text('Tu conversación con Obratek',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              ]))),
              const SizedBox(height: 10), Expanded(child: chat),
            ]);
          }))
        else
          const Expanded(child: Center(child: Text('Preparando tu soporte...'))),
      ]));
  }
}
