import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';

/// Componentes compartidos por el soporte de clientes y el de administración.
class SupportPlanPill extends StatelessWidget {
  final String plan;
  const SupportPlanPill(this.plan, {super.key});
  @override
  Widget build(BuildContext context) {
    final isPlus = plan == 'plus';
    final isPaid = plan == 'suscrito';
    final color = isPlus ? AppPalette.primary
      : isPaid ? AppPalette.teal : AppPalette.muted;
    final bg = isPlus ? AppPalette.primarySoft
      : isPaid ? const Color(0xFFE7FAFD) : AppPalette.background;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isPlus ? Icons.workspace_premium_outlined :
          isPaid ? Icons.verified_outlined : Icons.person_outline,
          color: color, size: 16),
        const SizedBox(width: 6),
        Text(supportPlanLabel(plan), style: TextStyle(color: color,
          fontWeight: FontWeight.w800, fontSize: 12)),
      ]));
  }
}

class SupportChatWindow extends StatefulWidget {
  final String title, subtitle, status;
  final bool viewingAsClient, canSend, isBusy;
  final List<SupportChatMessage> messages;
  final Future<void> Function(String) onSend;
  const SupportChatWindow({super.key, required this.title, required this.subtitle,
    required this.status, required this.viewingAsClient,
    required this.canSend, required this.isBusy,
    required this.messages, required this.onSend});
  @override
  State<SupportChatWindow> createState() => _SupportChatWindowState();
}

class _SupportChatWindowState extends State<SupportChatWindow> {
  final editor = TextEditingController();
  final scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => jumpToLast());
  }

  @override
  void didUpdateWidget(covariant SupportChatWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => jumpToLast());
    }
  }

  void jumpToLast() {
    if (mounted && scroll.hasClients) {
      scroll.animateTo(scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
    }
  }

  Future<void> submit() async {
    final body = editor.text.trim();
    if (!widget.canSend || widget.isBusy || body.isEmpty) return;
    try {
      await widget.onSend(body);
      if (mounted) editor.clear();
    } catch (e) {
      if (mounted) showSnack(context, 'No se pudo enviar: $e', error: true);
    }
  }

  @override
  void dispose() {
    editor.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SectionSurface(padding: EdgeInsets.zero,
    child: ClipRRect(borderRadius: BorderRadius.circular(17), child: Column(children: [
      Container(padding: const EdgeInsets.fromLTRB(20, 17, 20, 16),
        decoration: const BoxDecoration(color: Colors.white,
          border: Border(bottom: BorderSide(color: AppPalette.border))),
        child: Row(children: [
          const CircleAvatar(radius: 23, backgroundColor: AppPalette.navy,
            child: Icon(Icons.support_agent_rounded, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(widget.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppPalette.muted, fontSize: 11)),
          ])),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(color: widget.status == 'abierta'
              ? const Color(0xFFE5F8F1) : const Color(0xFFFFEEF0),
              borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(widget.status == 'abierta' ? Icons.circle : Icons.lock_outline,
                size: 10, color: widget.status == 'abierta'
                  ? AppPalette.success : AppPalette.danger),
              const SizedBox(width: 5),
              Text(widget.status == 'abierta' ? 'Abierto' : 'Cerrado',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: widget.status == 'abierta'
                    ? AppPalette.success : AppPalette.danger)),
            ])),
        ])),
      Expanded(child: Container(color: const Color(0xFFF9FAFE),
        child: widget.messages.isEmpty
          ? const Center(child: EmptyNotice(
              icon: Icons.chat_bubble_outline,
              title: 'Comienza la conversación',
              detail: 'Escribe tu mensaje. Quedará registrado para el equipo de soporte.'))
          : ListView.builder(controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final message = widget.messages[index];
                final mine = widget.viewingAsClient
                  ? message.authorRole == 'cliente'
                  : message.authorRole != 'cliente';
                return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 540),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 13),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: mine ? AppPalette.navy : Colors.white,
                        border: mine ? null : Border.all(color: AppPalette.border),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(mine ? 16 : 4),
                          bottomRight: Radius.circular(mine ? 4 : 16))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(message.authorName, style: TextStyle(
                          color: mine ? AppPalette.cyan : AppPalette.primary,
                          fontWeight: FontWeight.w800, fontSize: 11)),
                        const SizedBox(height: 6),
                        Text(message.body, style: TextStyle(
                          height: 1.5, color: mine ? Colors.white : AppPalette.ink,
                          fontSize: 13.5)),
                        const SizedBox(height: 6),
                        Text('${displayDate(message.createdAt)} · '
                             '${message.createdAt.toLocal().hour.toString().padLeft(2, '0')}:'
                             '${message.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 10,
                            color: mine ? const Color(0xFFB8C6E2) : AppPalette.muted)),
                      ])),
                  ));
              }),
      )),
      Container(padding: const EdgeInsets.fromLTRB(14, 12, 14, 15),
        decoration: const BoxDecoration(color: Colors.white,
          border: Border(top: BorderSide(color: AppPalette.border))),
        child: Column(children: [
          if (!widget.canSend) const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Esta conversación está cerrada. Un agente puede reabrirla.',
              style: TextStyle(color: AppPalette.muted, fontSize: 11))),
          Row(children: [
            Expanded(child: TextField(controller: editor, enabled: widget.canSend,
              maxLines: 3, minLines: 1, maxLength: 5000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                counterText: '', hintText: 'Escribe tu mensaje de soporte...',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
            const SizedBox(width: 9),
            IconButton.filled(onPressed: widget.canSend && !widget.isBusy ? submit : null,
              tooltip: 'Enviar mensaje',
              icon: widget.isBusy ? const SizedBox(width: 17, height: 17,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded)),
          ]),
          const SizedBox(height: 5),
          const Align(alignment: Alignment.centerLeft,
            child: Text('El chat es en tiempo real; la atención humana depende del horario del equipo.',
              style: TextStyle(color: AppPalette.muted, fontSize: 10.5))),
        ])),
    ])));
}
