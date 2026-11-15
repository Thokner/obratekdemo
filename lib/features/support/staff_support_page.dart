import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';
import 'support_widgets.dart';

class StaffSupportPage extends StatefulWidget {
  final ObratekRepository repository;
  final bool isAdmin;
  const StaffSupportPage({super.key, required this.repository, required this.isAdmin});
  @override
  State<StaffSupportPage> createState() => _StaffSupportPageState();
}

class _StaffSupportPageState extends State<StaffSupportPage> {
  List<SupportThread> inbox = [];
  List<PortalClient> clients = [];
  SupportThreadDetail? detail;
  int? selectedId, liveRoom;
  bool loading = true, showPlans = false, sending = false, updatingPlan = false;
  String? error;
  String filter = '';
  Timer? poll;
  StreamSubscription<int>? live;

  @override
  void initState() {
    super.initState();
    loadInbox();
    poll = Timer.periodic(const Duration(seconds: 12), (_) async {
      if (showPlans) return;
      await loadInbox(silent: true);
      if (selectedId != null) await loadDetail(selectedId!, silent: true);
    });
  }

  Future<void> loadInbox({bool silent = false}) async {
    if (!silent && mounted) setState(() => loading = true);
    try {
      final list = await widget.repository.staffSupportInbox();
      if (mounted) setState(() { inbox = list; loading = false; error = null; });
    } catch (e) {
      if (mounted) setState(() { error = '$e'; loading = false; });
    }
  }

  Future<void> loadDetail(int id, {bool silent = false}) async {
    if (!silent) setState(() { selectedId = id; detail = null; });
    try {
      final data = await widget.repository.staffSupportDetail(id);
      if (!mounted || selectedId != id) return;
      setState(() => detail = data);
      if (!AppConfig.demoMode && liveRoom != id) {
        live?.cancel();
        liveRoom = id;
        live = widget.repository.supportEvents(id).listen((_) {
          loadDetail(id, silent: true);
          loadInbox(silent: true);
        }, onError: (_) { liveRoom = null; });
      }
    } catch (e) {
      if (mounted && !silent) showSnack(context, '$e', error: true);
    }
  }

  Future<void> loadClients() async {
    if (!widget.isAdmin) return;
    setState(() => loading = true);
    try {
      final list = await widget.repository.staffClients();
      if (mounted) setState(() { clients = list; error = null; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = '$e'; loading = false; });
    }
  }

  Future<void> selectTab(bool plans) async {
    if (plans && !widget.isAdmin) return;
    setState(() { showPlans = plans; error = null; });
    if (plans) {
      await live?.cancel(); liveRoom = null;
      await loadClients();
    } else {
      await loadInbox();
    }
  }

  Future<void> reply(String body) async {
    final id = selectedId;
    if (id == null) return;
    setState(() => sending = true);
    try {
      await widget.repository.staffSupportReply(id, body);
      await loadDetail(id, silent: true);
      await loadInbox(silent: true);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> changeStatus(SupportThread thread) async {
    final next = thread.status == 'abierta' ? 'cerrada' : 'abierta';
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(next == 'cerrada' ? 'Cerrar conversación' : 'Reabrir conversación'),
      content: Text(next == 'cerrada'
        ? 'El cliente no podrá escribir hasta que el equipo la reabra.'
        : 'El cliente podrá volver a enviar mensajes según su plan.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirmar')),
      ]));
    if (confirm != true) return;
    try {
      await widget.repository.staffSupportStatus(thread.id, next);
      await loadDetail(thread.id, silent: true);
      await loadInbox(silent: true);
    } catch (e) {
      if (mounted) showSnack(context, 'No se pudo cambiar el estado: $e', error: true);
    }
  }

  Future<void> updatePlan(PortalClient client, String plan) async {
    if (!widget.isAdmin || updatingPlan || client.supportPlan == plan) return;
    final yes = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Cambiar clasificación de cliente'),
      content: Text('¿Asignar ${supportPlanLabel(plan)} a ${client.name}? '
        'Esto cambia el acceso al chat en vivo, pero no realiza cobros.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true),
          child: const Text('Guardar clasificación')),
      ]));
    if (yes != true) return;
    setState(() => updatingPlan = true);
    try {
      await widget.repository.staffSupportPlan(client.id, plan);
      await loadClients();
      if (mounted) showSnack(context, 'Clasificación actualizada y auditada.');
    } catch (e) {
      if (mounted) showSnack(context, 'No se pudo actualizar: $e', error: true);
    } finally {
      if (mounted) setState(() => updatingPlan = false);
    }
  }

  @override
  void dispose() {
    poll?.cancel();
    live?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageTitle(eyebrow: 'Atención al cliente', title: 'Soporte en vivo',
          subtitle: 'Conversa con tus clientes. Los Plus aparecen primero en la bandeja.',
          trailing: Wrap(spacing: 7, children: [
            ChoiceChip(label: const Text('Conversaciones'),
              selected: !showPlans, onSelected: (_) => selectTab(false)),
            if (widget.isAdmin) ChoiceChip(label: const Text('Clasificar clientes'),
              selected: showPlans, onSelected: (_) => selectTab(true)),
          ])),
        const SizedBox(height: 14),
        if (AppConfig.demoMode) const Padding(padding: EdgeInsets.only(bottom: 9),
          child: Text('DEMO · Datos ficticios, no se cobran suscripciones.',
            style: TextStyle(color: AppPalette.teal, fontSize: 11))),
        if (error != null) Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Text('Error al actualizar: $error',
            style: const TextStyle(color: AppPalette.danger))),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator())
          : showPlans ? planContent() : conversationContent()),
      ]));

  Widget conversationContent() => LayoutBuilder(builder: (context, c) {
    final wide = c.maxWidth >= 780;
    final chat = detail == null
      ? SectionSurface(child: Center(child: EmptyNotice(
          icon: Icons.forum_outlined, title: 'Selecciona una conversación',
          detail: 'Los chats Suscritos y Plus se gestionan desde esta pantalla.')))
      : Column(children: [
          if (!wide) Align(alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: () => setState(() {
              selectedId = null; detail = null;
            }), icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a conversaciones'))),
          Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SupportPlanPill(detail!.thread.plan), const SizedBox(width: 8),
              const Spacer(),
              OutlinedButton.icon(onPressed: () => changeStatus(detail!.thread),
                icon: Icon(detail!.thread.status == 'abierta'
                  ? Icons.lock_outline : Icons.lock_open_outlined, size: 17),
                label: Text(detail!.thread.status == 'abierta' ? 'Cerrar' : 'Reabrir')),
            ])),
          Expanded(child: SupportChatWindow(
            title: detail!.thread.customerName,
            subtitle: detail!.thread.customerEmail,
            status: detail!.thread.status,
            viewingAsClient: false,
            canSend: detail!.thread.status == 'abierta', isBusy: sending,
            messages: detail!.messages, onSend: reply)),
        ]);
    final conversations = SectionSurface(padding: EdgeInsets.zero,
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(17), child: Row(children: [
          const Expanded(child: Text('Bandeja de soporte',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          IconButton(onPressed: () => loadInbox(), tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh)),
        ])),
        const SoftDivider(),
        Expanded(child: inbox.isEmpty
          ? const EmptyNotice(icon: Icons.mark_chat_read_outlined,
              title: 'Sin conversaciones',
              detail: 'Aquí aparecerán los chats iniciados por clientes Suscritos y Plus.')
          : ListView.builder(itemCount: inbox.length, itemBuilder: (context, i) {
            final t = inbox[i];
            return Material(color: t.id == selectedId ? AppPalette.primarySoft : Colors.white,
              child: InkWell(onTap: () => loadDetail(t.id),
                child: Padding(padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14), child: Row(children: [
                  CircleAvatar(backgroundColor: t.priority == 'plus'
                    ? AppPalette.primarySoft : const Color(0xFFE6F7FB),
                    child: Icon(t.priority == 'plus' ? Icons.workspace_premium_outlined
                      : Icons.person_outline, color: t.priority == 'plus'
                      ? AppPalette.primary : AppPalette.teal)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.customerName, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(children: [SupportPlanPill(t.plan), const SizedBox(width: 7),
                        Icon(t.status == 'abierta' ? Icons.circle : Icons.lock_outline,
                          color: t.status == 'abierta'
                            ? AppPalette.success : AppPalette.muted, size: 11)]),
                    ])),
                  const Icon(Icons.chevron_right, size: 17, color: AppPalette.muted),
                ]))));
          })),
      ]));
    if (!wide) {
      return selectedId == null ? conversations : chat;
    }
    return Row(children: [
      SizedBox(width: 323, child: conversations),
      const SizedBox(width: 14),
      Expanded(child: chat),
    ]);
  });

  Widget planContent() {
    final shown = clients.where((c) =>
      '${c.name} ${c.email}'.toLowerCase().contains(filter.toLowerCase())).toList();
    final free = clients.where((c) => c.supportPlan == 'no_suscrito').length;
    final basic = clients.where((c) => c.supportPlan == 'suscrito').length;
    final plus = clients.where((c) => c.supportPlan == 'plus').length;
    return SectionSurface(child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 13, runSpacing: 8, children: [
          SupportPlanPill('no_suscrito'), Text('$free clientes'),
          SupportPlanPill('suscrito'), Text('$basic clientes'),
          SupportPlanPill('plus'), Text('$plus clientes'),
        ]),
        const SizedBox(height: 14),
        const Text('Los cambios aquí sólo definen el acceso al servicio. '
          'La confirmación de pagos y renovaciones se integrará más adelante.',
          style: TextStyle(color: AppPalette.muted, fontSize: 12)),
        const SizedBox(height: 14),
        TextField(onChanged: (value) => setState(() => filter = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search), hintText: 'Buscar cliente por nombre o correo')),
        const SizedBox(height: 10),
        Expanded(child: ListView.separated(itemCount: shown.length,
          separatorBuilder: (_, __) => const SoftDivider(),
          itemBuilder: (context, i) {
            final client = shown[i];
            return Padding(padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(children: [
                CircleAvatar(backgroundColor: AppPalette.navy,
                  child: Text(client.name.isNotEmpty ? client.name[0] : 'C',
                    style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(client.email, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppPalette.muted, fontSize: 11)),
                  ])),
                const SizedBox(width: 10),
                DropdownButton<String>(value: client.supportPlan,
                  onChanged: updatingPlan ? null : (v) {
                    if (v != null) updatePlan(client, v);
                  },
                  items: const [
                    DropdownMenuItem(value: 'no_suscrito', child: Text('No suscrito')),
                    DropdownMenuItem(value: 'suscrito', child: Text('Suscrito')),
                    DropdownMenuItem(value: 'plus', child: Text('Plus')),
                  ]),
              ]));
          })),
      ]));
  }
}
