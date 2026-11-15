import 'package:flutter/material.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';

class ClientProjectCard extends StatelessWidget {
  final ClientProject project;
  final VoidCallback onTap;
  const ClientProjectCard({super.key, required this.project, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(21), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppPalette.primarySoft,
                borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.apartment_rounded, color: AppPalette.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(project.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 3),
              Text(project.code, style: const TextStyle(color: AppPalette.muted, fontSize: 12)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: AppPalette.muted),
          ]),
          const SizedBox(height: 17),
          Row(children: [
            Expanded(child: Text(projectStatusLabel(project.status),
              style: const TextStyle(color: AppPalette.muted, fontSize: 12))),
            Text('${project.progress}%', style: const TextStyle(
              color: AppPalette.primary, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 9),
          ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(
            value: project.progress / 100.0, minHeight: 9,
            backgroundColor: AppPalette.primarySoft,
            color: project.progress == 100 ? AppPalette.teal : AppPalette.primary)),
          if ((project.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 15),
            Row(children: [const Icon(Icons.place_outlined, size: 17, color: AppPalette.muted),
              const SizedBox(width: 6),
              Expanded(child: Text(project.address!, maxLines: 2,
                style: const TextStyle(color: AppPalette.muted, fontSize: 12))),
            ]),
          ],
        ],
      )),
    ),
  );
}

class ClientRequestCard extends StatelessWidget {
  final ClientRequestItem request;
  final VoidCallback onTap;
  const ClientRequestCard({super.key, required this.request, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(child: InkWell(
    borderRadius: BorderRadius.circular(20), onTap: onTap,
    child: Padding(padding: const EdgeInsets.all(18), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(request.subject, style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15))),
          const SizedBox(width: 8),
          StatusPill(request.status),
        ]),
        const SizedBox(height: 8),
        Text('${request.code} · ${displayDate(request.createdAt)}',
          style: const TextStyle(color: AppPalette.muted, fontSize: 11)),
        if (request.projectName != null) ...[
          const SizedBox(height: 6),
          Text(request.projectName!, style: const TextStyle(
            color: AppPalette.primary, fontSize: 12)),
        ],
        const SizedBox(height: 8),
        Text(request.description, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppPalette.muted, height: 1.4)),
      ],
    )),
  ));
}

class ClientProjectDetailPage extends StatefulWidget {
  final ClientProject project;
  final ObratekRepository repository;
  final VoidCallback onRequest;
  const ClientProjectDetailPage({super.key, required this.project,
    required this.repository, required this.onRequest});
  @override
  State<ClientProjectDetailPage> createState() => _ClientProjectDetailPageState();
}

class _ClientProjectDetailPageState extends State<ClientProjectDetailPage> {
  late Future<List<ClientUpdate>> updates = widget.repository.clientProjectUpdates(widget.project.id);
  void reload() => setState(() => updates = widget.repository.clientProjectUpdates(widget.project.id));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle de construcción')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageTitle(eyebrow: widget.project.code, title: widget.project.name,
            subtitle: widget.project.address ?? 'Construcción asignada a tu cuenta'),
          const SizedBox(height: 18),
          ClientProjectCard(project: widget.project, onTap: () {}),
          const SizedBox(height: 14),
          SectionSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeading(title: 'Resumen del proyecto'),
            const SizedBox(height: 12),
            Text((widget.project.summary ?? '').isEmpty
              ? 'El equipo publicará aquí el próximo resumen de avance.' : widget.project.summary!,
              style: const TextStyle(color: AppPalette.muted, height: 1.6)),
            if (widget.project.estimatedEnd != null) ...[
              const SizedBox(height: 12),
              Text('Entrega estimada: ${displayDate(widget.project.estimatedEnd!)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: widget.onRequest,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Solicitar algo sobre esta obra')),
          ])),
          const SizedBox(height: 22),
          SectionHeading(title: 'Historial de avances',
            caption: 'Actualizaciones compartidas por el equipo de Obratek',
            trailing: IconButton(onPressed: reload, tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh))),
          const SizedBox(height: 12),
          AsyncPanel<List<ClientUpdate>>(future: updates, onRetry: reload,
            builder: (items) => items.isEmpty
              ? const SectionSurface(child: EmptyNotice(
                  title: 'Sin avances publicados',
                  detail: 'Cuando el equipo registre un avance visible para clientes, aparecerá aquí.'))
              : Column(children: [for (final u in items)
                Padding(padding: const EdgeInsets.only(bottom: 12),
                  child: SectionSurface(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(displayDate(u.createdAt), style: const TextStyle(
                        color: AppPalette.muted, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(u.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(u.detail, style: const TextStyle(height: 1.5)),
                    ]))),
              ])),
        ]))),
    ])),
  );
}

class NewClientRequestDialog extends StatefulWidget {
  final List<ClientProject> projects;
  final int? initialProjectId;
  final ObratekRepository repository;
  const NewClientRequestDialog({super.key, required this.projects,
    required this.repository, this.initialProjectId});
  @override
  State<NewClientRequestDialog> createState() => _NewClientRequestDialogState();
}

class _NewClientRequestDialogState extends State<NewClientRequestDialog> {
  final form = GlobalKey<FormState>();
  final subject = TextEditingController();
  final detail = TextEditingController();
  int? projectId;
  String category = 'consulta';
  bool busy = false;
  @override
  void initState() { super.initState(); projectId = widget.initialProjectId; }
  @override
  void dispose() { subject.dispose(); detail.dispose(); super.dispose(); }
  Future<void> save() async {
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    try {
      await widget.repository.createClientRequest({
        'project_id': projectId, 'category': category,
        'subject': subject.text.trim(), 'description': detail.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nueva solicitud'),
    content: SizedBox(width: 490, child: SingleChildScrollView(child: Form(
      key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int?>(
          initialValue: projectId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Construcción relacionada'),
          items: [const DropdownMenuItem<int?>(value: null, child: Text('Solicitud general')),
            for (final p in widget.projects)
              DropdownMenuItem<int?>(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))],
          onChanged: (v) => setState(() => projectId = v),
        ),
        const SizedBox(height: 13),
        DropdownButtonFormField<String>(
          initialValue: category,
          decoration: const InputDecoration(labelText: 'Tipo de solicitud'),
          items: const [
            DropdownMenuItem(value: 'consulta', child: Text('Consulta')),
            DropdownMenuItem(value: 'cambio', child: Text('Solicitar cambio')),
            DropdownMenuItem(value: 'visita', child: Text('Agendar visita')),
            DropdownMenuItem(value: 'documento', child: Text('Solicitar documento')),
            DropdownMenuItem(value: 'incidencia', child: Text('Reportar problema')),
            DropdownMenuItem(value: 'otro', child: Text('Otro')),
          ],
          onChanged: (v) => setState(() => category = v ?? 'consulta'),
        ),
        const SizedBox(height: 13),
        TextFormField(controller: subject, maxLength: 180,
          decoration: const InputDecoration(labelText: 'Asunto *'),
          validator: (v) => (v?.trim().length ?? 0) < 4 ? 'Describe el asunto' : null),
        const SizedBox(height: 8),
        TextFormField(controller: detail, maxLines: 5, maxLength: 10000,
          decoration: const InputDecoration(labelText: '¿Qué necesitas? *',
            alignLabelWithHint: true),
          validator: (v) => (v?.trim().length ?? 0) < 10 ? 'Escribe al menos 10 caracteres' : null),
      ]),
    ))),
    actions: [
      TextButton(onPressed: busy ? null : () => Navigator.pop(context, false),
        child: const Text('Cancelar')),
      FilledButton(onPressed: busy ? null : save,
        child: Text(busy ? 'Enviando...' : 'Enviar solicitud')),
    ],
  );
}

class RequestConversationPage extends StatefulWidget {
  final ClientRequestItem request;
  final ObratekRepository repository;
  final bool staff;
  const RequestConversationPage({super.key, required this.request,
    required this.repository, this.staff = false});
  @override
  State<RequestConversationPage> createState() => _RequestConversationPageState();
}
class _RequestConversationPageState extends State<RequestConversationPage> {
  final message = TextEditingController();
  bool busy = false;
  late Future<List<PortalMessage>> future = load();
  Future<List<PortalMessage>> load() => widget.repository.portalMessages(
    widget.request.id, staff: widget.staff);
  void reload() => setState(() => future = load());
  Future<void> send() async {
    if (message.text.trim().length < 2) return;
    setState(() => busy = true);
    try {
      await widget.repository.sendPortalMessage(widget.request.id,
        message.text.trim(), staff: widget.staff);
      message.clear();
      reload();
    } catch (e) { if (mounted) showSnack(context, '$e', error: true); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { message.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final closed = !widget.staff && (widget.request.status == 'resuelta' ||
      widget.request.status == 'rechazada');
    return Scaffold(
      appBar: AppBar(title: Text(widget.request.code)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: SectionSurface(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(widget.request.subject,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                StatusPill(widget.request.status),
              ]),
              const SizedBox(height: 8),
              Text(widget.request.description, style: const TextStyle(height: 1.5)),
            ]))),
          Expanded(child: AsyncPanel<List<PortalMessage>>(future: future,
            onRetry: reload, builder: (items) => ListView(padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8), children: [
              if (items.isEmpty) const EmptyNotice(title: 'Aún no hay respuestas',
                detail: 'Los mensajes sobre esta solicitud se mostrarán aquí.'),
              for (final m in items) Padding(padding: const EdgeInsets.only(bottom: 10),
                child: Align(alignment: m.role == 'cliente'
                  ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(constraints: const BoxConstraints(maxWidth: 590),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: m.role == 'cliente' ? AppPalette.primarySoft : Colors.white,
                      border: Border.all(color: AppPalette.border),
                      borderRadius: BorderRadius.circular(15)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${m.author} · ${displayDate(m.createdAt)}',
                        style: const TextStyle(color: AppPalette.muted, fontSize: 11)),
                      const SizedBox(height: 7), Text(m.body),
                    ]))),
              ),
            ]))),
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: closed ? const Text('Esta solicitud está cerrada.',
              style: TextStyle(color: AppPalette.muted))
            : Row(children: [
                Expanded(child: TextField(controller: message, maxLines: 3,
                  minLines: 1, decoration: const InputDecoration(hintText: 'Escribe tu mensaje...'))),
                const SizedBox(width: 9),
                IconButton.filled(tooltip: 'Enviar mensaje',
                  onPressed: busy ? null : send, icon: const Icon(Icons.send_rounded)),
              ])),
        ]),
      ))),
    );
  }
}
