import 'package:flutter/material.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';
import '../client/client_common.dart';

class StaffPortalPage extends StatelessWidget {
  final ObratekRepository repository;
  final bool embedded;
  final int initialTab;
  const StaffPortalPage({super.key, required this.repository,
    this.embedded = false, this.initialTab = 0});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3, initialIndex: initialTab,
    child: Builder(builder: (context) {
      const tabs = TabBar(tabs: [
        Tab(icon: Icon(Icons.people_outline), text: 'Clientes'),
        Tab(icon: Icon(Icons.apartment_outlined), text: 'Obras'),
        Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Solicitudes'),
      ]);
      final content = Column(children: [
        const Material(color: Colors.white, child: tabs),
        Expanded(child: TabBarView(children: [
          _StaffClientsTab(repository: repository),
          _StaffProjectsTab(repository: repository),
          _StaffRequestsTab(repository: repository),
        ])),
      ]);
      return embedded ? content : Scaffold(
        appBar: AppBar(title: const Text('Obratek · Gestión de clientes')),
        body: content,
      );
    }),
  );
}

class _StaffClientsTab extends StatefulWidget {
  final ObratekRepository repository;
  const _StaffClientsTab({required this.repository});
  @override
  State<_StaffClientsTab> createState() => _StaffClientsTabState();
}
class _StaffClientsTabState extends State<_StaffClientsTab> {
  late Future<List<PortalClient>> data = widget.repository.staffClients();
  void reload() => setState(() => data = widget.repository.staffClients());
  Future<void> review(PortalClient client, String status) async {
    try {
      await widget.repository.reviewClient(client.id, status);
      reload();
      if (mounted) showSnack(context, status == 'approved' ? 'Cliente aprobado' : 'Registro rechazado');
    } catch (e) { if (mounted) showSnack(context, '$e', error: true); }
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 950),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageTitle(eyebrow: 'Administración', title: 'Cuentas de clientes',
          subtitle: 'Los registros nuevos no tienen acceso a ninguna construcción hasta aprobarlos y asignarlos.',
          trailing: IconButton(onPressed: reload, tooltip: 'Actualizar', icon: const Icon(Icons.refresh))),
        const SizedBox(height: 19),
        AsyncPanel<List<PortalClient>>(future: data, onRetry: reload, builder: (clients) {
          if (clients.isEmpty) return const SectionSurface(child: EmptyNotice(
            title: 'Todavía no hay clientes registrados',
            detail: 'Los nuevos registros aparecerán aquí en estado pendiente.'));
          final ordered = [...clients]..sort((a, b) {
            if (a.status == 'pending' && b.status != 'pending') return -1;
            if (a.status != 'pending' && b.status == 'pending') return 1;
            return b.id.compareTo(a.id);
          });
          return Column(children: [for (final c in ordered) Padding(
            padding: const EdgeInsets.only(bottom: 12), child: SectionSurface(
              child: Wrap(crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16, runSpacing: 12, children: [
                  const CircleAvatar(backgroundColor: AppPalette.primarySoft,
                    child: Icon(Icons.person_outline, color: AppPalette.primary)),
                  SizedBox(width: 260, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(c.email, style: const TextStyle(color: AppPalette.muted,
                      fontSize: 12)),
                  ])),
                  Text(c.status == 'pending' ? 'Pendiente' :
                    c.status == 'approved' ? 'Aprobado' : 'Rechazado',
                    style: TextStyle(fontWeight: FontWeight.w700,
                      color: c.status == 'approved' ? AppPalette.teal : AppPalette.muted)),
                  if (c.status == 'pending') ...[
                    FilledButton.icon(onPressed: () => review(c, 'approved'),
                      icon: const Icon(Icons.check), label: const Text('Aprobar')),
                    OutlinedButton(onPressed: () => review(c, 'rejected'),
                      child: const Text('Rechazar')),
                  ],
                  if (c.status == 'rejected') OutlinedButton(
                    onPressed: () => review(c, 'approved'), child: const Text('Aprobar')),
                ]))),
          ]);
        }),
      ]))),
  ]);
}

class _StaffProjectsTab extends StatefulWidget {
  final ObratekRepository repository;
  const _StaffProjectsTab({required this.repository});
  @override
  State<_StaffProjectsTab> createState() => _StaffProjectsTabState();
}
class _StaffProjectsTabState extends State<_StaffProjectsTab> {
  late Future<List<ClientProject>> data = widget.repository.staffProjects();
  void reload() => setState(() => data = widget.repository.staffProjects());

  Future<void> create() async {
    final name = TextEditingController();
    final address = TextEditingController();
    final description = TextEditingController();
    final summary = TextEditingController();
    final form = GlobalKey<FormState>();
    final save = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar construcción'),
        content: SizedBox(width: 485, child: SingleChildScrollView(child: Form(
          key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(
              labelText: 'Nombre de la construcción *'),
              validator: (v) => (v?.trim().length ?? 0) < 4 ? 'Ingresa un nombre' : null),
            const SizedBox(height: 13),
            TextFormField(controller: address, decoration: const InputDecoration(
              labelText: 'Dirección (opcional)')),
            const SizedBox(height: 13),
            TextFormField(controller: description, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción interna')),
            const SizedBox(height: 13),
            TextFormField(controller: summary, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Resumen visible al cliente')),
          ]),
        ))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (form.currentState?.validate() ?? false) Navigator.pop(ctx, true);
          }, child: const Text('Crear construcción'))],
      ));
    if (save == true) {
      try {
        await widget.repository.staffCreateProject({
          'name': name.text.trim(), 'address': address.text.trim(),
          'description': description.text.trim(),
          'customer_summary': summary.text.trim(),
        });
        reload();
        if (mounted) showSnack(context, 'Construcción creada. Asigna clientes desde su detalle.');
      } catch (e) { if (mounted) showSnack(context, '$e', error: true); }
    }
    name.dispose(); address.dispose(); description.dispose(); summary.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageTitle(eyebrow: 'Gestión de obras', title: 'Construcciones',
          subtitle: 'Registra obras, actualiza avances y decide qué cliente puede ver cada una.',
          trailing: FilledButton.icon(onPressed: create,
            icon: const Icon(Icons.add), label: const Text('Nueva obra'))),
        const SizedBox(height: 20),
        AsyncPanel<List<ClientProject>>(future: data, onRetry: reload,
          builder: (projects) => projects.isEmpty
            ? const SectionSurface(child: EmptyNotice(title: 'Sin construcciones',
                detail: 'Registra la primera construcción desde el botón Nueva obra.'))
            : Column(children: [for (final p in projects)
                Padding(padding: const EdgeInsets.only(bottom: 11),
                  child: ClientProjectCard(project: p, onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) =>
                      StaffProjectDetailPage(repository: widget.repository, original: p)));
                    reload();
                  })),
              ])),
      ]))),
  ]);
}

class StaffProjectDetailPage extends StatefulWidget {
  final ObratekRepository repository;
  final ClientProject original;
  const StaffProjectDetailPage({super.key, required this.repository,
    required this.original});
  @override
  State<StaffProjectDetailPage> createState() => _StaffProjectDetailPageState();
}
class _StaffProjectDetailPageState extends State<StaffProjectDetailPage> {
  late ClientProject project = widget.original;
  late Future<List<ProjectAccess>> access = widget.repository.staffProjectClients(project.id);
  late Future<List<ClientUpdate>> updates = widget.repository.staffProjectUpdates(project.id);
  late Future<List<PortalClient>> clients = widget.repository.staffClients();
  void reload() => setState(() {
    access = widget.repository.staffProjectClients(project.id);
    updates = widget.repository.staffProjectUpdates(project.id);
    clients = widget.repository.staffClients();
  });

  Future<void> edit() async {
    String status = project.status;
    double progress = project.progress.toDouble();
    final summary = TextEditingController(text: project.summary ?? '');
    final data = await showDialog<Map<String, dynamic>>(context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, updateState) => AlertDialog(
        title: const Text('Actualizar construcción'),
        content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            DropdownButtonFormField<String>(initialValue: status,
              decoration: const InputDecoration(labelText: 'Etapa'),
              items: const [
                DropdownMenuItem(value: 'planificacion', child: Text('Planificación')),
                DropdownMenuItem(value: 'en_construccion', child: Text('En construcción')),
                DropdownMenuItem(value: 'pausada', child: Text('Pausada')),
                DropdownMenuItem(value: 'finalizada', child: Text('Finalizada')),
              ], onChanged: (v) => updateState(() => status = v ?? status)),
            const SizedBox(height: 18),
            Text('Avance: ${progress.round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
            Slider(value: progress, max: 100, divisions: 20,
              label: '${progress.round()}%', onChanged: (v) => updateState(() => progress = v)),
            TextField(controller: summary, minLines: 3, maxLines: 6, maxLength: 3000,
              decoration: const InputDecoration(labelText: 'Resumen visible para clientes',
                alignLabelWithHint: true)),
          ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, {
            'status': status, 'progress_percent': progress.round(),
            'customer_summary': summary.text.trim(),
          }), child: const Text('Guardar cambios'))],
      )));
    if (data != null) {
      try {
        final p = await widget.repository.staffEditProject(project.id, data);
        setState(() => project = p);
        if (mounted) showSnack(context, 'Avance actualizado');
      } catch (e) { if (mounted) showSnack(context, '$e', error: true); }
    }
    summary.dispose();
  }

  Future<void> addUpdate() async {
    final title = TextEditingController();
    final detail = TextEditingController();
    bool visible = true;
    final form = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, change) => AlertDialog(
        title: const Text('Publicar avance de obra'),
        content: SizedBox(width: 480, child: Form(key: form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Título *'),
              validator: (v) => (v?.trim().length ?? 0) < 3 ? 'Falta un título' : null),
            const SizedBox(height: 12),
            TextFormField(controller: detail, maxLines: 5,
              decoration: const InputDecoration(labelText: 'Descripción *'),
              validator: (v) => (v?.trim().length ?? 0) < 3 ? 'Describe el avance' : null),
            CheckboxListTile(contentPadding: EdgeInsets.zero,
              title: const Text('Visible para los clientes asignados'),
              subtitle: const Text('Desactiva para dejar una nota interna'),
              value: visible, onChanged: (v) => change(() => visible = v ?? false)),
          ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (form.currentState?.validate() ?? false) Navigator.pop(ctx, {
              'title': title.text.trim(), 'detail': detail.text.trim(), 'visible': visible,
            });
          }, child: const Text('Guardar avance'))],
      )));
    if (result != null) {
      try {
        await widget.repository.staffPostProjectUpdate(project.id,
          result['title'] as String, result['detail'] as String, result['visible'] as bool);
        reload();
        if (mounted) showSnack(context, 'Actualización registrada');
      } catch (e) { if (mounted) showSnack(context, '$e', error: true); }
    }
    title.dispose(); detail.dispose();
  }

  Future<void> assign(List<PortalClient> registered, List<ProjectAccess> existing) async {
    final assigned = existing.where((a) => a.active).map((a) => a.userId).toSet();
    final available = registered.where((c) => c.status == 'approved' &&
      !assigned.contains(c.id)).toList();
    if (available.isEmpty) { showSnack(context, 'No hay clientes aprobados pendientes de asignación'); return; }
    final chosen = await showDialog<int>(context: context,
      builder: (ctx) => SimpleDialog(title: const Text('Asignar construcción a cliente'),
        children: [for (final c in available) SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, c.id),
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('${c.name} · ${c.email}'))),
        ]));
    if (chosen == null) return;
    try {
      await widget.repository.staffGrantProjectAccess(project.id, chosen);
      reload();
      if (mounted) showSnack(context, 'Cliente vinculado a la construcción');
    } catch (e) { if (mounted) showSnack(context, '$e', error: true); }
  }
  Future<void> revoke(ProjectAccess value) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Quitar acceso'),
      content: Text('¿Quitar a ${value.name} el acceso a esta construcción?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false),
        child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Quitar acceso'))],
    ));
    if (yes != true) return;
    try {
      await widget.repository.staffChangeProjectAccess(project.id, value.userId, false);
      reload();
      if (mounted) showSnack(context, 'Permiso retirado');
    } catch (e) { if (mounted) showSnack(context, '$e', error: true); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(project.code)),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 850),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageTitle(eyebrow: 'Administrar construcción', title: project.name,
            subtitle: 'Actualiza avances, publica hitos y asigna clientes.'),
          const SizedBox(height: 17),
          ClientProjectCard(project: project, onTap: edit),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: edit, icon: const Icon(Icons.tune),
            label: const Text('Editar etapa, porcentaje y resumen')),
          const SizedBox(height: 28),
          SectionHeading(title: 'Clientes con acceso',
            caption: 'Sólo los clientes asignados podrán ver esta construcción.'),
          const SizedBox(height: 12),
          AsyncPanel<List<ProjectAccess>>(future: access, onRetry: reload,
            builder: (accesses) => AsyncPanel<List<PortalClient>>(future: clients,
              onRetry: reload, builder: (all) => SectionSurface(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final a in accesses.where((a) => a.active))
                    ListTile(contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: Text(a.name), subtitle: Text(a.email),
                      trailing: IconButton(tooltip: 'Retirar acceso',
                        onPressed: () => revoke(a), icon: const Icon(Icons.person_remove_outlined))),
                  if (accesses.every((a) => !a.active)) const Text('Sin clientes asignados.'),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(onPressed: () => assign(all, accesses),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Asignar cliente aprobado')),
                ])))),
          const SizedBox(height: 27),
          SectionHeading(title: 'Actualizaciones y avances',
            caption: 'Publica información visible al cliente o notas internas.',
            trailing: IconButton(onPressed: reload, icon: const Icon(Icons.refresh))),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: addUpdate, icon: const Icon(Icons.add),
            label: const Text('Registrar avance')),
          const SizedBox(height: 12),
          AsyncPanel<List<ClientUpdate>>(future: updates, onRetry: reload,
            builder: (items) => items.isEmpty
              ? const SectionSurface(child: EmptyNotice(title: 'Sin avances registrados',
                  detail: 'Agrega una actualización de la construcción.'))
              : Column(children: [for (final u in items) Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionSurface(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${displayDate(u.createdAt)} · ${u.visibleToClient ? 'Visible para clientes' : 'Nota interna'}',
                        style: TextStyle(fontSize: 11,
                          color: u.visibleToClient ? AppPalette.teal : AppPalette.muted)),
                      const SizedBox(height: 8),
                      Text(u.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5), Text(u.detail),
                    ]))),
                ])),
        ]))),
    ])),
  );
}

class _StaffRequestsTab extends StatefulWidget {
  final ObratekRepository repository;
  const _StaffRequestsTab({required this.repository});
  @override
  State<_StaffRequestsTab> createState() => _StaffRequestsTabState();
}
class _StaffRequestsTabState extends State<_StaffRequestsTab> {
  late Future<List<ClientRequestItem>> data = widget.repository.staffRequests();
  void reload() => setState(() => data = widget.repository.staffRequests());
  Future<void> editStatus(ClientRequestItem r) async {
    String choice = r.status;
    final value = await showDialog<String>(context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, change) => AlertDialog(
        title: Text('Estado de ${r.code}'),
        content: DropdownButtonFormField<String>(initialValue: choice,
          items: const [
            DropdownMenuItem(value: 'recibida', child: Text('Recibida')),
            DropdownMenuItem(value: 'en_revision', child: Text('En revisión')),
            DropdownMenuItem(value: 'en_proceso', child: Text('En proceso')),
            DropdownMenuItem(value: 'resuelta', child: Text('Resuelta')),
            DropdownMenuItem(value: 'rechazada', child: Text('Rechazada')),
          ], onChanged: (v) => change(() => choice = v ?? choice)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, choice),
            child: const Text('Guardar'))],
      )));
    if (value == null) return;
    try {
      await widget.repository.staffChangeRequestStatus(r.id, value);
      reload();
      if (mounted) showSnack(context, 'Estado actualizado');
    } catch (e) { if (mounted) showSnack(context, '$e', error: true); }
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 930),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageTitle(eyebrow: 'Atención al cliente', title: 'Solicitudes recibidas',
          subtitle: 'Revisa cambios, visitas, consultas y reportes de los clientes.',
          trailing: IconButton(onPressed: reload, tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh))),
        const SizedBox(height: 19),
        AsyncPanel<List<ClientRequestItem>>(future: data, onRetry: reload,
          builder: (requests) => requests.isEmpty
            ? const SectionSurface(child: EmptyNotice(title: 'Sin solicitudes',
                detail: 'Los mensajes enviados por los clientes aparecerán aquí.'))
            : Column(children: [for (final r in requests) Column(children: [
                ClientRequestCard(request: r, onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) =>
                    RequestConversationPage(request: r, repository: widget.repository, staff: true)));
                  reload();
                }),
                Padding(padding: const EdgeInsets.only(bottom: 12), child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(onPressed: () => editStatus(r),
                    icon: const Icon(Icons.edit_note),
                    label: Text('Cambiar estado · ${requestStatusLabel(r.status)}')))),
              ]),
            ])),
      ]))),
  ]);
}
