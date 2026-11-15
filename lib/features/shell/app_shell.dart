import 'package:flutter/material.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../layout/workspace_frame.dart';
import '../dashboard/dashboard_page.dart';
import '../work_orders/work_orders_page.dart';
import '../work_orders/order_dialogs.dart';
import '../bitacoras/bitacoras_page.dart';
import '../planning/planning_page.dart';
import '../repairs/repairs_page.dart';
import '../modules/module_page.dart';
import '../staff_portal/staff_portal_page.dart';
import '../audit/audit_page.dart';
import '../support/staff_support_page.dart';

class AppShell extends StatefulWidget {
  final ObratekRepository repository;
  final UserSession user;
  final VoidCallback onLogout;
  const AppShell({super.key, required this.repository,
    required this.user, required this.onLogout});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String selected = 'dashboard';
  int refreshKey = 0;

  List<WorkspaceItem> get items {
    if (widget.user.role == 'auditor') {
      return const [
        WorkspaceItem('audit', 'Auditoría', Icons.shield_outlined, 'Revisión'),
        WorkspaceItem('settings', 'Información', Icons.info_outline, 'Revisión'),
      ];
    }
    return [
      const WorkspaceItem('dashboard', 'Dashboard', Icons.space_dashboard_outlined, 'General'),
      const WorkspaceItem('orders', 'Órdenes de trabajo', Icons.assignment_outlined, 'Operaciones'),
      const WorkspaceItem('bitacoras', 'Bitácoras', Icons.menu_book_outlined, 'Operaciones'),
      const WorkspaceItem('planning', 'Planificación', Icons.calendar_month_outlined, 'Operaciones'),
      const WorkspaceItem('repairs', 'Reparaciones', Icons.handyman_outlined, 'Operaciones'),
      if (widget.user.canEdit) ...const [
        WorkspaceItem('projects', 'Proyectos y obras', Icons.layers_outlined, 'Operaciones'),
        WorkspaceItem('clients', 'Clientes y obras', Icons.groups_outlined, 'Relaciones'),
        WorkspaceItem('requests', 'Solicitudes', Icons.forum_outlined, 'Relaciones'),
        WorkspaceItem('support', 'Soporte en vivo', Icons.support_agent_outlined, 'Relaciones'),
        WorkspaceItem('quotes', 'Cotizaciones', Icons.request_quote_outlined, 'Administración'),
        WorkspaceItem('materials', 'Materiales y compras', Icons.shopping_cart_outlined, 'Administración'),
        WorkspaceItem('finances', 'Finanzas', Icons.bar_chart_rounded, 'Administración'),
        WorkspaceItem('workers', 'Trabajadores', Icons.engineering_outlined, 'Maestros'),
        WorkspaceItem('companies', 'Empresas', Icons.business_outlined, 'Maestros'),
        WorkspaceItem('contacts', 'Contactos', Icons.contact_page_outlined, 'Maestros'),
        WorkspaceItem('properties', 'Inmuebles', Icons.apartment_outlined, 'Maestros'),
        WorkspaceItem('services', 'Servicios', Icons.build_outlined, 'Maestros'),
        WorkspaceItem('activities', 'Actividades', Icons.checklist_rounded, 'Maestros'),
      ],
      if (widget.user.role == 'admin')
        const WorkspaceItem('audit', 'Auditoría', Icons.shield_outlined, 'Sistema'),
      const WorkspaceItem('settings', 'Configuración', Icons.settings_outlined, 'Sistema'),
    ];
  }

  void go(String id) => setState(() => selected = id);

  void openModule(String title, String kind) {
    final target = switch (kind) {
      'quotes' => 'quotes', 'workers' => 'workers',
      'companies' => 'companies', 'contacts' => 'contacts',
      'properties' => 'properties', 'services' => 'services',
      'materials' => 'materials', 'finances' => 'finances',
      'activities' => 'activities', _ => 'settings',
    };
    if (items.any((e) => e.id == target)) go(target);
  }

  Future<void> createOrder() async {
    final made = await showCreateOrderDialog(context, widget.repository);
    if (made && mounted) setState(() { refreshKey++; selected = 'orders'; });
  }

  Future<void> searchOrders() async {
    try {
      final orders = await widget.repository.workOrders();
      if (!mounted) return;
      await showSearch<void>(context: context, delegate: _OrdersSearch(
        orders: orders, onSelect: () => go('orders')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo buscar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = items.any((e) => e.id == selected)
      ? selected : items.first.id;
    final name = items.firstWhere((e) => e.id == current).title;
    return WorkspaceFrame(
      selected: current, items: items, onSelect: go,
      title: name, subtitle: 'Administración  ›  $name',
      userName: widget.user.name, userRole: widget.user.role,
      onLogout: widget.onLogout,
      onSearch: widget.user.role == 'auditor' ? null : searchOrders,
      onPrimary: widget.user.canEdit ? createOrder : null,
      primaryText: 'Nueva OT',
      child: KeyedSubtree(key: ValueKey('$current:$refreshKey'),
        child: _page(current)),
    );
  }

  Widget _module(String title, String kind) => ModulePage(
    key: ValueKey(kind), title: title, kind: kind,
    repository: widget.repository, user: widget.user, embedded: true);

  Widget _page(String id) => switch (id) {
    'dashboard' => DashboardPage(repository: widget.repository, user: widget.user,
      onNewOrder: createOrder, onGoToOrders: () => go('orders'),
      onOpenModule: openModule, onOpenSection: go),
    'orders' => WorkOrdersPage(repository: widget.repository, user: widget.user,
      onNewOrder: createOrder),
    'bitacoras' => BitacorasPage(repository: widget.repository),
    'planning' => PlanningPage(repository: widget.repository, user: widget.user),
    'repairs' => const RepairsPage(),
    'projects' => StaffPortalPage(repository: widget.repository,
      embedded: true, initialTab: 1),
    'clients' => StaffPortalPage(repository: widget.repository,
      embedded: true, initialTab: 0),
    'requests' => StaffPortalPage(repository: widget.repository,
      embedded: true, initialTab: 2),
    'support' => StaffSupportPage(repository: widget.repository,
      isAdmin: widget.user.role == 'admin'),
    'quotes' => _module('Cotizaciones', 'quotes'),
    'materials' => _module('Materiales y compras', 'materials'),
    'finances' => _module('Finanzas', 'finances'),
    'workers' => _module('Trabajadores', 'workers'),
    'companies' => _module('Empresas', 'companies'),
    'contacts' => _module('Contactos', 'contacts'),
    'properties' => _module('Inmuebles', 'properties'),
    'services' => _module('Servicios', 'services'),
    'activities' => _module('Actividades', 'activities'),
    'audit' => AuditPage(repository: widget.repository),
    _ => const _ConfigPage(),
  };
}

class _OrdersSearch extends SearchDelegate<void> {
  final List<WorkOrder> orders;
  final VoidCallback onSelect;
  _OrdersSearch({required this.orders, required this.onSelect});
  @override String get searchFieldLabel => 'Buscar órdenes de trabajo';
  @override List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), tooltip: 'Limpiar',
      onPressed: () => query = ''),
  ];
  @override Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back), tooltip: 'Volver',
    onPressed: () => close(context, null));
  @override Widget buildResults(BuildContext context) => buildSuggestions(context);
  @override Widget buildSuggestions(BuildContext context) {
    final q = query.toLowerCase().trim();
    final visible = orders.where((o) => q.isEmpty ||
      '${o.code} ${o.description} ${o.company ?? ''}'.toLowerCase().contains(q))
      .take(30);
    return ListView(children: [
      for (final o in visible) ListTile(
        leading: const Icon(Icons.assignment_outlined),
        title: Text('${o.code} · ${o.description}'),
        subtitle: Text(statusLabel(o.status)),
        onTap: () { close(context, null); onSelect(); },
      ),
    ]);
  }
}

class _ConfigPage extends StatelessWidget {
  const _ConfigPage();
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(26),
    children: [
      Text('Configuración y permisos', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('La matriz definitiva de roles y filtros todavía requiere validar las reglas reales de AppSheet.'),
      const SizedBox(height: 20),
      const Card(child: Padding(padding: EdgeInsets.all(22), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Controles ya presentes', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('• Sesiones autenticadas y comprobaciones de permisos en la API'),
          Text('• Clientes aprobados y acceso explícito por construcción'),
          Text('• Auditoría de acciones registradas en backend'),
          SizedBox(height: 19),
          Text('Pendiente de validación', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('• Matriz final de roles, firmas, adjuntos y alcance por empresa'),
          Text('• Reglas Show_If, Editable_If, Valid_If y Required_If'),
          Text('• Automatizaciones y migración de las 34 tablas'),
        ]))),
    ]);
}
