import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../layout/workspace_frame.dart';
import '../../shared/widgets/ob_ui.dart';
import 'client_common.dart';
import '../support/client_support_page.dart';
import '../support/support_widgets.dart';

class ClientShell extends StatefulWidget {
  final ObratekRepository repository;
  final UserSession user;
  final VoidCallback onLogout;
  const ClientShell({super.key, required this.repository, required this.user,
    required this.onLogout});
  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  String selected = 'home';
  late Future<ClientOverview> data;
  @override
  void initState() {
    super.initState();
    data = widget.user.customerStatus == 'approved'
      ? widget.repository.clientOverview()
      : Future.value(const ClientOverview([], [], 0));
  }

  void reload() => setState(() => data = widget.repository.clientOverview());
  Future<void> refresh() async { reload(); await data; }

  Future<void> newRequest(List<ClientProject> projects, {int? projectId}) async {
    final created = await showDialog<bool>(context: context,
      builder: (_) => NewClientRequestDialog(repository: widget.repository,
        projects: projects, initialProjectId: projectId));
    if (created == true && mounted) {
      setState(() { selected = 'requests'; data = widget.repository.clientOverview(); });
      showSnack(context, 'Solicitud enviada. El equipo de Obratek podrá revisarla.');
    }
  }

  void openProject(ClientProject project, List<ClientProject> projects) {
    Navigator.push(context, MaterialPageRoute(builder: (_) =>
      ClientProjectDetailPage(project: project, repository: widget.repository,
        onRequest: () async {
          await newRequest(projects, projectId: project.id);
        })));
  }

  void openRequest(ClientRequestItem request) {
    Navigator.push(context, MaterialPageRoute(builder: (_) =>
      RequestConversationPage(request: request, repository: widget.repository)));
  }

  List<WorkspaceItem> get sections => const [
    WorkspaceItem('home', 'Inicio', Icons.home_outlined, 'Mi espacio'),
    WorkspaceItem('projects', 'Mis construcciones', Icons.apartment_outlined, 'Mi espacio'),
    WorkspaceItem('updates', 'Avances', Icons.insights_outlined, 'Seguimiento'),
    WorkspaceItem('requests', 'Solicitudes', Icons.assignment_outlined, 'Seguimiento'),
    WorkspaceItem('support', 'Soporte en vivo', Icons.support_agent_outlined, 'Ayuda'),
    WorkspaceItem('documents', 'Documentos', Icons.folder_outlined, 'Seguimiento'),
    WorkspaceItem('agenda', 'Agenda', Icons.event_outlined, 'Seguimiento'),
    WorkspaceItem('profile', 'Perfil', Icons.person_outline, 'Mi cuenta'),
  ];

  Future<void> searchClient() async {
    final overview = await data;
    if (!mounted) return;
    await showSearch<void>(context: context, delegate: _ClientSearch(
      overview: overview, onNavigate: (id) => setState(() => selected = id)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.customerStatus != 'approved') {
      return Scaffold(appBar: AppBar(title: const Text('Obratek · Clientes'),
        actions: [IconButton(onPressed: widget.onLogout, tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout))]),
        body: Center(child: Padding(padding: const EdgeInsets.all(22),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 490),
            child: SectionSurface(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.verified_user_outlined, color: AppPalette.primary, size: 47),
              const SizedBox(height: 17),
              Text(widget.user.customerStatus == 'rejected'
                  ? 'Tu solicitud no fue aprobada' : 'Estamos revisando tu registro',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text('El equipo debe validar tu cuenta y asignarte las construcciones correspondientes. Mientras tanto no podrás consultar información de obras.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, color: AppPalette.muted)),
              const SizedBox(height: 19),
              OutlinedButton.icon(onPressed: widget.onLogout,
                icon: const Icon(Icons.logout), label: const Text('Volver al acceso')),
            ]))))),
      );
    }
    final current = sections.firstWhere((x) => x.id == selected);
    return WorkspaceFrame(
      selected: selected, items: sections, onSelect: (id) => setState(() => selected = id),
      title: selected == 'home' ? 'Portal de clientes' : current.title,
      subtitle: 'Portal del cliente  ›  ${current.title}',
      userName: widget.user.name, userRole: 'Cliente', isClient: true,
      onLogout: widget.onLogout, onSearch: searchClient,
      onPrimary: () async {
        try { final overview = await data; await newRequest(overview.projects); }
        catch (e) { if (mounted) showSnack(context, '$e', error: true); }
      },
      primaryText: 'Nueva solicitud',
      child: selected == 'support'
        ? ClientSupportPage(repository: widget.repository,
            onGoToRequests: () => setState(() => selected = 'requests'))
        : selected == 'profile' ? accountView()
        : selected == 'documents' || selected == 'agenda'
          ? _ClientFuturePage(isDocuments: selected == 'documents')
          : AsyncPanel<ClientOverview>(future: data, onRetry: reload,
              builder: (overview) => RefreshIndicator(onRefresh: refresh,
                child: ListView(physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(23), children: [
                    Center(child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1420),
                      child: switch (selected) {
                        'home' => overviewView(overview),
                        'projects' => projectsView(overview),
                        'updates' => updatesView(overview),
                        _ => requestsView(overview),
                      },
                    )),
                  ]))),
    );
  }

  Widget overviewView(ClientOverview o) {
    final average = o.projects.isEmpty ? 0 :
      (o.projects.map((p) => p.progress).reduce((a, b) => a + b) / o.projects.length).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('¡Bienvenido, ${widget.user.name.split(' ').first}!',
        style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 5),
      const Text('Consulta el avance de tus construcciones, comunica solicitudes y revisa las novedades publicadas.',
        style: TextStyle(color: AppPalette.muted, height: 1.5)),
      if (AppConfig.demoMode) const Padding(padding: EdgeInsets.only(top: 8),
        child: Text('DEMOSTRACIÓN · Construcciones y mensajes ficticios.',
          style: TextStyle(color: AppPalette.teal, fontSize: 11))),
      const SizedBox(height: 20),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 1000 ? 4 : c.maxWidth >= 600 ? 2 : 1;
        final width = (c.maxWidth - 14 * (cols - 1)) / cols;
        return Wrap(spacing: 14, runSpacing: 14, children: [
          SizedBox(width: width, child: _ClientKpi('Construcciones asignadas',
            '${o.projects.length}', Icons.apartment_outlined, AppPalette.primary)),
          SizedBox(width: width, child: _ClientKpi('Solicitudes abiertas',
            '${o.openRequests}', Icons.assignment_outlined, AppPalette.cyan)),
          SizedBox(width: width, child: _ClientKpi('Avance promedio',
            '$average%', Icons.insights_outlined, const Color(0xFF3385CC))),
          SizedBox(width: width, child: _ClientKpi('Solicitudes totales',
            '${o.requests.length}', Icons.forum_outlined, AppPalette.primary)),
        ]);
      }),
      const SizedBox(height: 19),
      SectionSurface(child: Row(children: [
        const CircleAvatar(radius: 24, backgroundColor: AppPalette.primarySoft,
          child: Icon(Icons.support_agent_outlined, color: AppPalette.primary)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Necesitas ayuda?', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('Consulta tu nivel de soporte y habla con Obratek desde la app.',
              style: TextStyle(fontSize: 12, color: AppPalette.muted)),
          ])),
        TextButton(onPressed: () => setState(() => selected = 'support'),
          child: const Text('Ir a soporte')),
      ])),
      const SizedBox(height: 19),
      LayoutBuilder(builder: (context, c) {
        final constructions = SectionSurface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SectionHeading(title: 'Mis construcciones',
              caption: 'Tus obras asignadas y su estado actual',
              trailing: TextButton(onPressed: () => setState(() => selected = 'projects'),
                child: const Text('Ver todas'))),
            const SizedBox(height: 15),
            if (o.projects.isEmpty)
              const EmptyNotice(title: 'Sin construcciones asignadas',
                detail: 'El administrador asignará tus proyectos.'),
            for (final p in o.projects.take(3)) Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ClientConstructionRow(project: p,
                onTap: () => openProject(p, o.projects))),
          ]));
        final updates = _LatestClientUpdates(repository: widget.repository,
          projects: o.projects);
        return c.maxWidth >= 1000 ? Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(flex: 6, child: constructions),
            const SizedBox(width: 16), Expanded(flex: 5, child: updates)])
          : Column(children: [constructions, const SizedBox(height: 15), updates]);
      }),
      const SizedBox(height: 19),
      SectionSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading(title: 'Mis solicitudes',
            caption: 'Consultas que has enviado al equipo',
            trailing: TextButton(onPressed: () => setState(() => selected = 'requests'),
              child: const Text('Ver todas'))),
          const SizedBox(height: 12),
          if (o.requests.isEmpty) const EmptyNotice(title: 'Sin solicitudes',
            detail: 'Puedes crear una solicitud desde el botón superior.'),
          for (final r in o.requests.take(4)) ClientRequestCard(
            request: r, onTap: () => openRequest(r)),
        ])),
    ]);
  }

  Widget updatesView(ClientOverview o) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PageTitle(eyebrow: 'Seguimiento', title: 'Avances publicados',
        subtitle: 'Actualizaciones oficiales de las construcciones asignadas a tu cuenta.'),
      const SizedBox(height: 17),
      _LatestClientUpdates(repository: widget.repository, projects: o.projects),
    ]);

  Widget projectGrid(List<ClientProject> items, List<ClientProject> all) =>
    LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth >= 750 ? (c.maxWidth - 16) / 2 : c.maxWidth;
      return Wrap(spacing: 16, runSpacing: 14, children: [for (final p in items)
        SizedBox(width: width, child: ClientProjectCard(project: p,
          onTap: () => openProject(p, all)))],
      );
    });

  Widget projectsView(ClientOverview o) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PageTitle(eyebrow: 'Mi espacio', title: 'Mis construcciones',
        subtitle: 'Revisa el avance, las fechas y los últimos hitos publicados.'),
      const SizedBox(height: 20),
      if (o.projects.isEmpty) const SectionSurface(child: EmptyNotice(
        title: 'Sin construcciones asignadas',
        detail: 'Un administrador vinculará las obras de tu cuenta.')),
      projectGrid(o.projects, o.projects),
    ]);

  Widget requestsView(ClientOverview o) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageTitle(eyebrow: 'Comunicación', title: 'Mis solicitudes',
        subtitle: 'Consultas, cambios, visitas, documentos e incidencias.',
        trailing: FilledButton.icon(onPressed: () => newRequest(o.projects),
          icon: const Icon(Icons.add), label: const Text('Nueva solicitud'))),
      const SizedBox(height: 18),
      if (o.requests.isEmpty) const SectionSurface(child: EmptyNotice(
        title: 'Aún no has enviado solicitudes',
        detail: 'Cuando envíes una solicitud podrás seguir su estado y conversar con Obratek.')),
      for (final r in o.requests) ClientRequestCard(request: r,
        onTap: () => openRequest(r)),
    ]);

  Widget accountView() => ListView(padding: const EdgeInsets.all(22), children: [
    Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageTitle(eyebrow: 'Mi cuenta', title: 'Datos de acceso',
          subtitle: 'Información básica de tu usuario.'),
        const SizedBox(height: 18),
        SectionSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.user.name, style: const TextStyle(fontSize: 19,
            fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(widget.user.email, style: const TextStyle(color: AppPalette.muted)),
          const SizedBox(height: 10),
          const Text('Cuenta de cliente aprobada', style: TextStyle(color: AppPalette.teal)),
          const SizedBox(height: 10),
          SupportPlanPill(widget.user.supportPlan),
          const SizedBox(height: 22),
          OutlinedButton.icon(onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_outlined), label: const Text('Cerrar sesión')),
        ])),
      ]))),
  ]);
}

class _ClientKpi extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _ClientKpi(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    height: 107, padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppPalette.border),
      boxShadow: const [BoxShadow(color: Color(0x110A244F),
        blurRadius: 12, offset: Offset(0, 3))]),
    child: Row(children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(
        color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, color: color, size: 26)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900,
            fontSize: 28, color: AppPalette.ink)),
        ])),
    ]));
}

class _ClientConstructionRow extends StatelessWidget {
  final ClientProject project;
  final VoidCallback onTap;
  const _ClientConstructionRow({required this.project, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: AppPalette.background,
      borderRadius: BorderRadius.circular(15)),
    child: LayoutBuilder(builder: (context, c) => Row(children: [
      Container(width: c.maxWidth > 490 ? 82 : 49,
        height: c.maxWidth > 490 ? 83 : 60,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [Color(0xFFD9F4FA), Color(0xFFE5E9FC)])),
        child: const Icon(Icons.apartment_rounded, size: 36, color: AppPalette.teal)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800)),
        Text(project.address ?? 'Sin dirección informada',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppPalette.muted, fontSize: 11)),
        const SizedBox(height: 9),
        Text('Avance: ${project.progress}%',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: project.progress.clamp(0, 100) / 100,
            minHeight: 7, color: AppPalette.primary,
            backgroundColor: AppPalette.border)),
      ])),
      const SizedBox(width: 10),
      IconButton(onPressed: onTap, tooltip: 'Ver construcción',
        icon: const Icon(Icons.chevron_right, color: AppPalette.primary)),
    ])));
}

class _LatestClientUpdates extends StatefulWidget {
  final ObratekRepository repository;
  final List<ClientProject> projects;
  const _LatestClientUpdates({required this.repository, required this.projects});
  @override
  State<_LatestClientUpdates> createState() => _LatestClientUpdatesState();
}

class _LatestClientUpdatesState extends State<_LatestClientUpdates> {
  late Future<List<ClientUpdate>> future = load();
  Future<List<ClientUpdate>> load() async {
    final nested = await Future.wait(widget.projects.map(
      (p) => widget.repository.clientProjectUpdates(p.id)));
    final all = nested.expand((x) => x).where((x) => x.visibleToClient).toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }
  @override
  void didUpdateWidget(_LatestClientUpdates oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projects.length != widget.projects.length) {
      setState(() => future = load());
    }
  }
  @override
  Widget build(BuildContext context) => SectionSurface(child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeading(title: 'Actualizaciones de Obratek',
        caption: 'Avances visibles para tus construcciones'),
      const SizedBox(height: 12),
      AsyncPanel<List<ClientUpdate>>(future: future,
        onRetry: () => setState(() => future = load()),
        builder: (updates) => updates.isEmpty
          ? const EmptyNotice(title: 'Sin publicaciones todavía',
              detail: 'Cuando Obratek publique novedades aparecerán aquí.')
          : Column(children: [for (final u in updates.take(8))
              ListTile(contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: AppPalette.primarySoft,
                  child: Icon(Icons.campaign_outlined, color: AppPalette.primary)),
                title: Text(u.title, style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700)),
                subtitle: Text('${u.detail}\n${displayDate(u.createdAt)}',
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppPalette.muted)),
              ),
            ])),
    ]));
}

class _ClientFuturePage extends StatelessWidget {
  final bool isDocuments;
  const _ClientFuturePage({required this.isDocuments});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24), children: [
      PageTitle(eyebrow: 'Portal de clientes',
        title: isDocuments ? 'Documentos' : 'Agenda',
        subtitle: isDocuments
          ? 'Espacio reservado para archivos publicados de tus construcciones.'
          : 'Espacio reservado para visitas y reuniones autorizadas.'),
      const SizedBox(height: 18),
      SectionSurface(child: EmptyNotice(
        icon: isDocuments ? Icons.folder_outlined : Icons.calendar_month_outlined,
        title: 'Este módulo todavía no está habilitado',
        detail: isDocuments
          ? 'Antes de mostrar documentos se implementarán permisos por archivo y enlaces temporales. No se expondrán documentos internos.'
          : 'Se habilitará cuando validemos los responsables, calendarios y reglas de visibilidad para clientes.',
      )),
    ]);
}

class _ClientSearch extends SearchDelegate<void> {
  final ClientOverview overview;
  final ValueChanged<String> onNavigate;
  _ClientSearch({required this.overview, required this.onNavigate});
  @override String get searchFieldLabel => 'Buscar en mis construcciones o solicitudes';
  @override List<Widget> buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];
  @override Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override Widget buildResults(BuildContext context) => buildSuggestions(context);
  @override Widget buildSuggestions(BuildContext context) {
    final q = query.toLowerCase().trim();
    return ListView(children: [
      for (final p in overview.projects.where((p) => q.isEmpty ||
          '${p.name} ${p.code}'.toLowerCase().contains(q)).take(15))
        ListTile(leading: const Icon(Icons.apartment_outlined),
          title: Text(p.name), subtitle: Text(p.code),
          onTap: () { close(context, null); onNavigate('projects'); }),
      for (final r in overview.requests.where((r) => q.isEmpty ||
          '${r.code} ${r.subject}'.toLowerCase().contains(q)).take(15))
        ListTile(leading: const Icon(Icons.assignment_outlined),
          title: Text(r.subject), subtitle: Text(r.code),
          onTap: () { close(context, null); onNavigate('requests'); }),
    ]);
  }
}
