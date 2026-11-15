import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';

/// El backend limita la visibilidad del historial; filtrar aquí nunca otorga permisos.
class AuditPage extends StatefulWidget {
  final ObratekRepository repository;
  final String? initialEntity, initialId;
  const AuditPage({super.key, required this.repository,
    this.initialEntity, this.initialId});
  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  late String entity = widget.initialEntity ?? '';
  String event = '';
  final entityId = TextEditingController();
  final userId = TextEditingController();
  DateTime? since;
  late Future<List<AuditEntry>> events;

  @override
  void initState() {
    super.initState();
    entityId.text = widget.initialId ?? '';
    events = load();
  }

  Future<List<AuditEntry>> load() => widget.repository.auditEvents(
    entity: entity.isEmpty ? null : entity,
    event: event.isEmpty ? null : event,
    entityId: entityId.text.trim().isEmpty ? null : entityId.text.trim(),
    actorId: int.tryParse(userId.text.trim()), since: since,
  );
  void refresh() => setState(() => events = load());

  @override
  void dispose() { entityId.dispose(); userId.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24), children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1320),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageTitle(eyebrow: 'Seguridad y trazabilidad', title: 'Auditoría general',
            subtitle: 'Revisa operaciones registradas: autor, fecha, módulo y valores modificados.',
            trailing: OutlinedButton.icon(onPressed: refresh,
              icon: const Icon(Icons.refresh), label: const Text('Actualizar'))),
          const SizedBox(height: 16),
          const SectionSurface(child: Row(children: [
            Icon(Icons.shield_outlined, color: AppPalette.teal),
            SizedBox(width: 12),
            Expanded(child: Text('Sólo los perfiles autorizados pueden leer este historial. Las contraseñas, tokens y ciertos datos sensibles se ocultan del registro.')),
          ])),
          const SizedBox(height: 16),
          SectionSurface(child: Wrap(spacing: 12, runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center, children: [
            SizedBox(width: 230, child: DropdownButtonFormField<String>(
              value: entity, decoration: const InputDecoration(labelText: 'Módulo'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Todos')),
                DropdownMenuItem(value: 'work_order', child: Text('Órdenes de trabajo')),
                DropdownMenuItem(value: 'work_log', child: Text('Bitácoras')),
                DropdownMenuItem(value: 'project', child: Text('Construcciones')),
                DropdownMenuItem(value: 'client', child: Text('Clientes')),
                DropdownMenuItem(value: 'client_request', child: Text('Solicitudes')),
                DropdownMenuItem(value: 'planning', child: Text('Planificación')),
                DropdownMenuItem(value: 'user', child: Text('Usuarios')),
              ], onChanged: (v) => setState(() => entity = v ?? ''))),
            SizedBox(width: 200, child: DropdownButtonFormField<String>(
              value: event, decoration: const InputDecoration(labelText: 'Acción'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Todas')),
                DropdownMenuItem(value: 'created', child: Text('Creación')),
                DropdownMenuItem(value: 'updated', child: Text('Modificación')),
                DropdownMenuItem(value: 'status_changed', child: Text('Cambio de estado')),
                DropdownMenuItem(value: 'login_success', child: Text('Inicio de sesión')),
              ], onChanged: (v) => setState(() => event = v ?? ''))),
            SizedBox(width: 160, child: TextField(controller: entityId,
              decoration: const InputDecoration(labelText: 'ID del registro'))),
            SizedBox(width: 145, child: TextField(controller: userId,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ID de usuario'))),
            OutlinedButton.icon(onPressed: () async {
              final picked = await showDatePicker(context: context,
                initialDate: since ?? DateTime.now(),
                firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (picked != null) setState(() => since = picked);
            }, icon: const Icon(Icons.event),
              label: Text(since == null ? 'Desde fecha' : displayDate(since!))),
            FilledButton.icon(onPressed: refresh,
              icon: const Icon(Icons.filter_alt_outlined), label: const Text('Aplicar filtros')),
            TextButton(onPressed: () { setState(() {
              entity = ''; event = ''; entityId.clear(); userId.clear(); since = null;
              events = load();
            }); }, child: const Text('Limpiar')),
          ])),
          const SizedBox(height: 16),
          AsyncPanel<List<AuditEntry>>(future: events, onRetry: refresh,
            builder: (entries) => entries.isEmpty
              ? const SectionSurface(child: EmptyNotice(
                  title: 'No hay eventos para estos filtros',
                  detail: 'Prueba con otra fecha o módulo; sólo aparecen acciones registradas por la aplicación.'))
              : SectionSurface(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Column(children: [
                    for (final item in entries) _AuditRow(item: item),
                  ]))),
        ]))),
    ]);
}

class _AuditRow extends StatelessWidget {
  final AuditEntry item;
  const _AuditRow({required this.item});
  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: CircleAvatar(backgroundColor: AppPalette.primarySoft,
      child: Icon(item.event == 'status_changed' ? Icons.sync_alt : Icons.history,
        color: AppPalette.primary, size: 21)),
    title: Text('${auditEventLabel(item.event)} · ${auditEntityLabel(item.entity)}',
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    subtitle: Text('${item.actorName} · ${displayDate(item.createdAt)} · ID ${item.entityId}',
      style: const TextStyle(color: AppPalette.muted, fontSize: 12)),
    childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
    children: [Align(alignment: Alignment.centerLeft, child: Wrap(
      spacing: 16, runSpacing: 12, children: [
        _AuditData(title: 'Antes', data: item.before),
        _AuditData(title: 'Después', data: item.after),
        if (item.requestId != null)
          Text('Solicitud técnica: ${item.requestId}',
            style: const TextStyle(fontSize: 11, color: AppPalette.muted)),
      ]))],
  );
}

class _AuditData extends StatelessWidget {
  final String title;
  final Map<String, dynamic>? data;
  const _AuditData({required this.title, required this.data});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 12,
        color: AppPalette.muted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 5),
      SelectableText(data == null ? 'Sin valores anteriores' :
        const JsonEncoder.withIndent('  ').convert(data),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
    ]));
}
