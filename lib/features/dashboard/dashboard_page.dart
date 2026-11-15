import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';

class DashboardPage extends StatefulWidget {
  final ObratekRepository repository;
  final UserSession user;
  final VoidCallback onNewOrder, onGoToOrders;
  final void Function(String, String) onOpenModule;
  final ValueChanged<String>? onOpenSection;
  const DashboardPage({super.key, required this.repository,
    required this.user, required this.onNewOrder,
    required this.onGoToOrders, required this.onOpenModule, this.onOpenSection});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _Overview {
  final DashboardSummary metrics;
  final List<WorkOrder> orders;
  final List<PlanItem> plans;
  final List<ClientProject> projects;
  final List<ClientRequestItem> requests;
  final List<AuditEntry> audits;
  final int activeClients;
  const _Overview(this.metrics, this.orders, this.plans,
    this.projects, this.requests, this.audits, this.activeClients);
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_Overview> future = fetch();
  Future<_Overview> fetch() async {
    final core = await Future.wait([
      widget.repository.summary(), widget.repository.workOrders(), widget.repository.plans(),
    ]);
    var projects = <ClientProject>[];
    var requests = <ClientRequestItem>[];
    var audits = <AuditEntry>[];
    var clients = 0;
    if (widget.user.canEdit) {
      try { projects = await widget.repository.staffProjects(); } catch (_) { /* Partial dashboard */ }
      try { requests = await widget.repository.staffRequests(); } catch (_) { /* Partial dashboard */ }
      try {
        clients = (await widget.repository.staffClients())
          .where((c) => c.status == 'approved').length;
      } catch (_) { /* Partial dashboard */ }
    }
    if (widget.user.role == 'admin') {
      try { audits = await widget.repository.auditEvents(); } catch (_) { /* Partial dashboard */ }
    }
    return _Overview(core[0] as DashboardSummary, core[1] as List<WorkOrder>,
      core[2] as List<PlanItem>, projects, requests, audits, clients);
  }

  void reload() => setState(() => future = fetch());

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async { reload(); await future; },
    child: ListView(padding: const EdgeInsets.fromLTRB(23, 22, 23, 28), children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('¡Bienvenido, ${widget.user.name.split(' ').first}!',
                style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              const Text('Resumen de proyectos, órdenes de trabajo y actividades de Obratek.',
                style: TextStyle(color: AppPalette.muted)),
            ])),
            IconButton(onPressed: reload, tooltip: 'Actualizar indicadores',
              icon: const Icon(Icons.refresh_rounded)),
          ]),
          if (AppConfig.demoMode) const Padding(padding: EdgeInsets.only(top: 9),
            child: Text('DEMOSTRACIÓN · Los indicadores y nombres son ficticios.',
              style: TextStyle(color: AppPalette.teal, fontSize: 11,
                fontWeight: FontWeight.w600))),
          const SizedBox(height: 21),
          AsyncPanel<_Overview>(future: future, onRetry: reload,
            builder: (data) => Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(builder: (context, c) {
                  final columns = c.maxWidth > 1160 ? 4 : c.maxWidth > 650 ? 2 : 1;
                  final w = (c.maxWidth - 15 * (columns - 1)) / columns;
                  return Wrap(spacing: 15, runSpacing: 15, children: [
                    SizedBox(width: w, child: _Kpi('Proyectos activos',
                      widget.user.canEdit ? '${data.projects.where((p) => p.status != 'finalizada').length}' : '—',
                      Icons.layers_outlined, AppPalette.primary,
                      'Construcciones registradas')),
                    SizedBox(width: w, child: _Kpi('OT en ejecución',
                      '${data.metrics.enEjecucion}', Icons.assignment_outlined,
                      AppPalette.cyan, 'Órdenes en curso')),
                    SizedBox(width: w, child: _Kpi('Clientes aprobados',
                      widget.user.canEdit ? '${data.activeClients}' : '—',
                      Icons.groups_outlined, const Color(0xFF277DCB),
                      'Con acceso autorizado')),
                    SizedBox(width: w, child: _Kpi('Solicitudes abiertas',
                      widget.user.canEdit ? '${data.requests.where((r) =>
                        !['resuelta','rechazada'].contains(r.status)).length}' : '—',
                      Icons.notifications_none, AppPalette.primary,
                      'Pendientes de gestión')),
                  ]);
                }),
                const SizedBox(height: 20),
                LayoutBuilder(builder: (context, c) {
                  final orders = _OrdersPanel(orders: data.orders,
                    onOpen: widget.onGoToOrders);
                  final timeline = _AuditPanel(audits: data.audits,
                    onOpen: widget.user.role == 'admin'
                      ? () => widget.onOpenSection?.call('audit') : null);
                  return c.maxWidth >= 1000 ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 7, child: orders), const SizedBox(width: 16),
                      Expanded(flex: 4, child: timeline),
                    ]) : Column(children: [orders, const SizedBox(height: 16), timeline]);
                }),
                const SizedBox(height: 20),
                LayoutBuilder(builder: (context, c) {
                  final widgets = [
                    _PlanningPanel(data: data),
                    _RequestsPanel(requests: data.requests, onOpen: widget.user.canEdit
                      ? () => widget.onOpenSection?.call('requests') : null),
                    _ProjectsPanel(projects: data.projects, onOpen: widget.user.canEdit
                      ? () => widget.onOpenSection?.call('projects') : null),
                  ];
                  if (c.maxWidth >= 1100) {
                    return Row(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [for (var i = 0; i < widgets.length; i++) ...[
                        if (i > 0) const SizedBox(width: 15),
                        Expanded(child: widgets[i]),
                      ]]);
                  }
                  return Column(children: [for (final widget in widgets) ...[
                    widget, const SizedBox(height: 15),
                  ]]);
                }),
              ])),
        ]))),
    ]),
  );
}

class _Kpi extends StatelessWidget {
  final String title, value, detail;
  final IconData icon;
  final Color color;
  const _Kpi(this.title, this.value, this.icon, this.color, this.detail);
  @override
  Widget build(BuildContext context) => Container(
    height: 116, padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppPalette.border),
      boxShadow: const [BoxShadow(color: Color(0x120B234B),
        blurRadius: 12, offset: Offset(0, 3))]),
    child: Row(children: [
      Container(width: 52, height: 56,
        decoration: BoxDecoration(color: color.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, size: 27, color: color)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 27,
            fontWeight: FontWeight.w900, color: AppPalette.ink)),
          Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: AppPalette.muted)),
        ])),
    ]),
  );
}

class _OrdersPanel extends StatelessWidget {
  final List<WorkOrder> orders;
  final VoidCallback onOpen;
  const _OrdersPanel({required this.orders, required this.onOpen});
  @override
  Widget build(BuildContext context) => SectionSurface(child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeading(title: 'Órdenes de trabajo (OT)',
        caption: 'Órdenes recientes y estado de ejecución',
        trailing: TextButton.icon(onPressed: onOpen,
          icon: const Icon(Icons.arrow_forward, size: 17), label: const Text('Ver todas'))),
      const SizedBox(height: 16),
      if (orders.isEmpty)
        const EmptyNotice(title: 'No hay órdenes',
          detail: 'Crea una orden para comenzar el seguimiento.'),
      if (orders.isNotEmpty) SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: DataTable(columnSpacing: 20, dataRowMinHeight: 54,
          dataRowMaxHeight: 60, horizontalMargin: 8,
          columns: const [
            DataColumn(label: Text('N.° OT')),
            DataColumn(label: Text('Descripción')),
            DataColumn(label: Text('Responsable')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Fecha')),
          ],
          rows: [for (final o in orders.take(6)) DataRow(
            onSelectChanged: (_) => onOpen(), cells: [
              DataCell(Text(o.code, style: const TextStyle(
                color: AppPalette.primary, fontWeight: FontWeight.w800))),
              DataCell(SizedBox(width: 190, child: Text(o.description,
                maxLines: 2, overflow: TextOverflow.ellipsis))),
              DataCell(Text(o.worker ?? 'Por asignar')),
              DataCell(StatusPill(o.status)),
              DataCell(Text(displayDate(o.createdAt))),
            ]),
          ])),
    ]));
}

class _AuditPanel extends StatelessWidget {
  final List<AuditEntry> audits;
  final VoidCallback? onOpen;
  const _AuditPanel({required this.audits, required this.onOpen});
  @override
  Widget build(BuildContext context) => SectionSurface(child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeading(title: 'Actividad y auditoría',
        caption: 'Movimientos registrados por el servidor',
        trailing: onOpen == null ? null : TextButton(
          onPressed: onOpen, child: const Text('Ver auditoría'))),
      const SizedBox(height: 12),
      if (audits.isEmpty) const EmptyNotice(
        title: 'Sin registros para mostrar',
        detail: 'Este panel sólo presenta acciones auditadas y autorizadas.'),
      for (final e in audits.take(5)) Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(radius: 16, backgroundColor: AppPalette.primarySoft,
            child: const Icon(Icons.history, size: 17, color: AppPalette.primary)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${auditEventLabel(e.event)} · ${auditEntityLabel(e.entity)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('${e.actorName} · ${displayDate(e.createdAt)}',
                style: const TextStyle(color: AppPalette.muted, fontSize: 11)),
            ])),
        ])),
    ]));
}

class _PlanningPanel extends StatelessWidget {
  final _Overview data;
  const _PlanningPanel({required this.data});
  @override
  Widget build(BuildContext context) {
    final total = data.metrics.total;
    final completed = data.metrics.finalizadas;
    final percentage = total == 0 ? 0 : ((completed / total) * 100).round();
    return SectionSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading(title: 'Planificación y avance',
          caption: 'Órdenes finalizadas y visitas programadas'),
        const SizedBox(height: 20),
        Row(children: [
          SizedBox(width: 98, height: 98, child: Stack(
            alignment: Alignment.center, children: [
              SizedBox(width: 91, height: 91, child: CircularProgressIndicator(
                value: total == 0 ? 0 : completed / total,
                strokeWidth: 10, strokeCap: StrokeCap.round,
                color: AppPalette.cyan,
                backgroundColor: AppPalette.border)),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$percentage%', style: const TextStyle(fontSize: 22,
                  fontWeight: FontWeight.w900)),
                const Text('OT cerradas', style: TextStyle(
                  fontSize: 9, color: AppPalette.muted)),
              ]),
            ])),
          const SizedBox(width: 15),
          Expanded(child: Column(children: [
            _LineStat('Finalizadas', '${data.metrics.finalizadas}'),
            _LineStat('En ejecución', '${data.metrics.enEjecucion}'),
            _LineStat('Planificadas', '${data.metrics.programadas}'),
          ])),
        ]),
        const SizedBox(height: 18),
        for (final p in data.plans.take(2)) ListTile(
          contentPadding: EdgeInsets.zero, dense: true,
          leading: const Icon(Icons.event_available_outlined, color: AppPalette.teal),
          title: Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(displayDate(p.date)),
        ),
      ]));
  }
}

class _LineStat extends StatelessWidget {
  final String label, value;
  const _LineStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(label,
        style: const TextStyle(fontSize: 11, color: AppPalette.muted))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ]));
}

class _RequestsPanel extends StatelessWidget {
  final List<ClientRequestItem> requests;
  final VoidCallback? onOpen;
  const _RequestsPanel({required this.requests, required this.onOpen});
  @override
  Widget build(BuildContext context) => SectionSurface(child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeading(title: 'Solicitudes de clientes',
        caption: 'Consultas y requerimientos recientes',
        trailing: onOpen == null ? null : TextButton(
          onPressed: onOpen, child: const Text('Ver todas'))),
      const SizedBox(height: 15),
      if (requests.isEmpty) const EmptyNotice(title: 'Sin solicitudes recientes',
        detail: 'Las consultas enviadas por clientes aparecerán aquí.'),
      for (final r in requests.take(4)) Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          const Icon(Icons.description_outlined, color: AppPalette.primary),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${r.code} · ${r.subject}', maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
              Text(r.projectName ?? 'Solicitud general',
                style: const TextStyle(fontSize: 10.5, color: AppPalette.muted)),
            ])),
          StatusPill(r.status),
        ])),
    ]));
}

class _ProjectsPanel extends StatelessWidget {
  final List<ClientProject> projects;
  final VoidCallback? onOpen;
  const _ProjectsPanel({required this.projects, required this.onOpen});
  @override
  Widget build(BuildContext context) => SectionSurface(child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeading(title: 'Proyectos en progreso',
        caption: 'Construcciones activas en Obratek',
        trailing: onOpen == null ? null : TextButton(
          onPressed: onOpen, child: const Text('Ver proyectos'))),
      const SizedBox(height: 15),
      if (projects.isEmpty) const EmptyNotice(title: 'No hay proyectos publicados',
        detail: 'Gestiona las construcciones desde Clientes y obras.'),
      for (final p in projects.take(4)) Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.apartment_outlined, color: AppPalette.teal),
            const SizedBox(width: 8),
            Expanded(child: Text(p.name, maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
            Text('${p.progress}%', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(7),
            child: LinearProgressIndicator(value: (p.progress.clamp(0, 100)) / 100,
              minHeight: 8, backgroundColor: AppPalette.border,
              color: AppPalette.primary)),
        ])),
    ]));
}
