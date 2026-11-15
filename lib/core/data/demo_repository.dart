import '../models/models.dart';
import 'repository.dart';

/// Datos 100% ficticios para probar la interfaz. NO son datos de Obratek.
class DemoRepository implements ObratekRepository {
  final _extraCatalog = <String, List<CatalogItem>>{};
  final _orders = <WorkOrder>[
    WorkOrder(id: 1, code: 'OT-2026-000001', description: 'Revisión de tablero eléctrico',
      status: 'en_ejecucion', createdAt: DateTime(2026, 11, 12),
      company: 'Empresa de ejemplo A', property: 'Instalación Norte',
      service: 'Mantenimiento', worker: 'Trabajador Demo'),
    WorkOrder(id: 2, code: 'OT-2026-000002', description: 'Inspección técnica preventiva',
      status: 'iniciada', createdAt: DateTime(2026, 11, 13),
      company: 'Empresa de ejemplo B', property: 'Planta Central',
      service: 'Inspección', worker: 'Trabajador Demo'),
    WorkOrder(id: 3, code: 'OT-2026-000003', description: 'Reparación de luminarias exteriores',
      status: 'finalizada', createdAt: DateTime(2026, 11, 10),
      company: 'Empresa de ejemplo A', property: 'Instalación Norte',
      service: 'Reparación', worker: 'Equipo Demo'),
    WorkOrder(id: 4, code: 'OT-2026-000004', description: 'Diagnóstico de sistema de climatización',
      status: 'en_ejecucion', createdAt: DateTime(2026, 11, 14),
      company: 'Empresa de ejemplo B', property: 'Planta Central',
      service: 'Diagnóstico', worker: 'Equipo Demo'),
  ];
  final _logs = <LogEntry>[
    LogEntry(id: 1, workOrderId: 1, code: 'OT-2026-000001',
      description: 'Se realiza inspección inicial y registro de observaciones.',
      author: 'Usuario de demostración', createdAt: DateTime(2026, 11, 13, 9, 20)),
    LogEntry(id: 2, workOrderId: 4, code: 'OT-2026-000004',
      description: 'Pendiente validación del diagnóstico por el supervisor.',
      author: 'Usuario de demostración', createdAt: DateTime(2026, 11, 14, 8, 45)),
  ];
  final _plans = <PlanItem>[
    PlanItem(id: 1, workOrderId: 2, code: 'OT-2026-000002',
      date: DateTime(2026, 11, 16), description: 'Visita preventiva programada',
      status: 'programada'),
    PlanItem(id: 2, workOrderId: 4, code: 'OT-2026-000004',
      date: DateTime(2026, 11, 18), description: 'Segunda revisión técnica',
      status: 'programada'),
  ];

  final List<AuditEntry> _audits = [
    AuditEntry(id: 1, entity: 'work_order', entityId: '1',
      event: 'status_changed', actorName: 'Administrador Demo', actorRole: 'admin',
      createdAt: DateTime(2026, 11, 14, 9, 30),
      before: const {'status': 'iniciada'}, after: const {'status': 'en_ejecucion'}),
    AuditEntry(id: 2, entity: 'project', entityId: '1',
      event: 'updated', actorName: 'Administrador Demo', actorRole: 'admin',
      createdAt: DateTime(2026, 11, 14, 8, 45), after: const {'progress_percent': 65}),
  ];

  @override
  Future<List<AuditEntry>> auditEvents({String? entity, String? event,
    String? entityId, int? actorId, DateTime? since, DateTime? until}) async {
    return _audits.where((a) =>
      (entity == null || entity.isEmpty || a.entity == entity) &&
      (event == null || event.isEmpty || a.event == event) &&
      (entityId == null || entityId.isEmpty || a.entityId == entityId) &&
      (actorId == null || actorId == 1) &&
      (since == null || !a.createdAt.isBefore(since)) &&
      (until == null || !a.createdAt.isAfter(until))).toList().reversed.toList();
  }

  @override
  Future<List<AuditEntry>> auditRecord(String entity, String entityId) =>
    auditEvents(entity: entity, entityId: entityId);

  @override
  Future<UserSession> login(String email, String password) async {
    final e = email.toLowerCase();
    _currentDemoClientId = 0;
    if (e.contains('cliente') || e.contains('pendiente') ||
        e.contains('plus') || e.contains('gratis') || e.contains('suscrito')) {
      _currentDemoClientId = e.contains('pendiente') ? 102
        : e.contains('plus') ? 103
        : e.contains('gratis') ? 104 : 101;
      final client = _clients.firstWhere((x) => x.id == _currentDemoClientId);
      return UserSession(client.name, client.email, 'cliente',
        customerStatus: client.status, supportPlan: client.supportPlan);
    }
    return const UserSession('Administrador Demo', 'admin@demo.local', 'admin');
  }

  @override
  Future<DashboardSummary> summary() async => DashboardSummary(
    total: _orders.length,
    iniciadas: _orders.where((x) => x.status == 'iniciada').length,
    enEjecucion: _orders.where((x) => x.status == 'en_ejecucion').length,
    finalizadas: _orders.where((x) => x.status == 'finalizada').length,
    programadas: _plans.where((x) => x.status == 'programada').length,
  );

  @override
  Future<List<WorkOrder>> workOrders() async => List.unmodifiable(_orders);

  @override
  Future<WorkOrder> createOrder(Map<String, dynamic> data) async {
    final next = _orders.map((x) => x.id).fold<int>(0, (a, b) => a > b ? a : b) + 1;
    final result = WorkOrder(id: next,
      code: 'OT-2026-${next.toString().padLeft(6, '0')}',
      description: data['description'] as String, status: 'iniciada',
      createdAt: DateTime.now(),
      company: data['company_id'] == 1 ? 'Empresa de ejemplo A' :
        data['company_id'] == 2 ? 'Empresa de ejemplo B' : null,
      contact: data['contact_id'] == 1 ? 'Contacto de ejemplo' : null,
      worker: data['assigned_worker_id'] == 1 ? 'Trabajador Demo' : null);
    _orders.insert(0, result);
    _audits.add(AuditEntry(id: _audits.length + 1, entity: 'work_order',
      entityId: '$next', event: 'created', actorName: 'Administrador Demo',
      actorRole: 'admin', createdAt: DateTime.now(),
      after: {'public_code': result.code, 'status': 'iniciada'}));
    return result;
  }

  @override
  Future<WorkOrder> changeStatus(int id, String status) async {
    final index = _orders.indexWhere((x) => x.id == id);
    if (index < 0) throw Exception('No se encontró la orden');
    final old = _orders[index];
    if ((old.status == 'finalizada' || old.status == 'descartada')) {
      throw Exception('La orden ya está cerrada');
    }
    final next = WorkOrder(id: old.id, code: old.code, description: old.description,
      status: status, createdAt: old.createdAt, company: old.company,
      contact: old.contact, property: old.property, service: old.service, worker: old.worker);
    _orders[index] = next;
    _audits.add(AuditEntry(id: _audits.length + 1, entity: 'work_order',
      entityId: '$id', event: 'status_changed', actorName: 'Administrador Demo',
      actorRole: 'admin', createdAt: DateTime.now(),
      before: {'status': old.status}, after: {'status': status}));
    return next;
  }

  @override
  Future<List<LogEntry>> logs() async => List.unmodifiable(_logs.reversed);

  @override
  Future<void> addLog(int orderId, String description) async {
    final order = _orders.firstWhere((x) => x.id == orderId);
    _logs.add(LogEntry(id: _logs.length + 1, workOrderId: orderId,
      code: order.code, description: description, author: 'Usuario de demostración',
      createdAt: DateTime.now()));
  }

  @override
  Future<List<PlanItem>> plans() async => List.unmodifiable(_plans);

  @override
  Future<void> addPlan(int orderId, DateTime day, String description) async {
    final order = _orders.firstWhere((x) => x.id == orderId);
    _plans.add(PlanItem(id: _plans.length + 1, workOrderId: orderId,
      code: order.code, date: day, description: description, status: 'programada'));
  }

  @override
  Future<List<CatalogItem>> catalog(String kind) async => [
    ...(switch (kind) {
    'workers' => const [CatalogItem(1, 'Trabajador Demo'), CatalogItem(2, 'Equipo Demo')],
    'companies' => const [CatalogItem(1, 'Empresa de ejemplo A'),
        CatalogItem(2, 'Empresa de ejemplo B')],
    'contacts' => const [CatalogItem(1, 'Contacto de ejemplo')],
    'properties' => const [CatalogItem(1, 'Instalación Norte'),
        CatalogItem(2, 'Planta Central')],
    'services' => const [CatalogItem(1, 'Mantenimiento'),
        CatalogItem(2, 'Reparación'), CatalogItem(3, 'Diagnóstico')],
    _ => [],
    }),
    ...?_extraCatalog[kind],
  ];

  @override
  Future<CatalogItem> addCatalog(String kind, String name) async {
    final item = CatalogItem(1000 + (_extraCatalog[kind]?.length ?? 0), name);
    _extraCatalog.putIfAbsent(kind, () => []).add(item);
    return item;
  }

  @override
  Future<List<QuoteInfo>> quotes() async => const [
    QuoteInfo(1, 'COT-DEMO-001', 'Empresa de ejemplo A', 'iniciada'),
    QuoteInfo(2, 'COT-DEMO-002', 'Empresa de ejemplo B', 'en_proceso'),
  ];

  @override
  Future<List<Map<String, dynamic>>> activities() async => [
    {'id': 1, 'title': 'Confirmar visita de inspección (ejemplo)', 'status': 'pendiente'},
    {'id': 2, 'title': 'Revisar avance de OT (ejemplo)', 'status': 'en_proceso'},
  ];

  int _currentDemoClientId = 0;
  final Map<int, int> _requestOwners = {1: 101};
  final List<PortalClient> _clients = [
    const PortalClient(id: 101, name: 'Cliente Suscrito Demo', email: 'cliente@demo.local', status: 'approved', supportPlan: 'suscrito'),
    const PortalClient(id: 102, name: 'Cliente de Prueba', email: 'pendiente@demo.local', status: 'pending'),
    const PortalClient(id: 103, name: 'Cliente Plus Demo', email: 'plus@demo.local', status: 'approved', supportPlan: 'plus'),
    const PortalClient(id: 104, name: 'Cliente sin Suscripción', email: 'gratis@demo.local', status: 'approved'),
  ];
  final List<ClientProject> _projects = [
    ClientProject(id: 1, code: 'OBR-2026-000001', name: 'Residencial Los Robles',
      status: 'en_construccion', progress: 64, address: 'Dirección ficticia 120, Santiago',
      summary: 'Obra gruesa terminada. Avanzamos en instalaciones interiores.',
      startDate: DateTime(2026, 10, 5), estimatedEnd: DateTime(2027, 2, 14)),
    ClientProject(id: 2, code: 'OBR-2026-000002', name: 'Ampliación de oficina',
      status: 'planificacion', progress: 15, address: 'Dirección ficticia 80, Santiago',
      summary: 'Proyecto en revisión de ingeniería y planificación.',
      startDate: DateTime(2026, 11, 1), estimatedEnd: DateTime(2027, 4, 20)),
  ];
  final Map<int, Set<int>> _access = {1: {101}, 2: {101}};
  final List<ClientUpdate> _updates = [
    ClientUpdate(id: 1, projectId: 1, title: 'Instalaciones interiores',
      detail: 'El equipo inició los trabajos eléctricos y sanitarios.', visibleToClient: true,
      createdAt: DateTime(2026, 11, 12)),
    ClientUpdate(id: 2, projectId: 1, title: 'Obra gruesa completada',
      detail: 'Terminamos la etapa estructural. Continuamos con las terminaciones.', visibleToClient: true,
      createdAt: DateTime(2026, 11, 5)),
  ];
  final List<ClientRequestItem> _clientRequests = [
    ClientRequestItem(id: 1, code: 'SOL-2026-000001', projectId: 1,
      projectName: 'Residencial Los Robles', requesterName: 'Cliente Demostración',
      category: 'visita', subject: 'Coordinar visita a la obra',
      description: 'Quisiera visitar el proyecto el próximo miércoles.', status: 'en_revision',
      createdAt: DateTime(2026, 11, 13)),
  ];
  final Map<int, List<PortalMessage>> _messages = {
    1: [PortalMessage(id: 1, author: 'Supervisor Demo', role: 'supervisor',
       body: 'Estamos revisando la disponibilidad del equipo.', createdAt: DateTime(2026, 11, 13, 15))],
  };

  @override
  void logout() => _currentDemoClientId = 0;

  @override
  Future<void> registerClient(String name, String email, String password, String phone) async {
    _clients.add(PortalClient(id: 100 + _clients.length + 1,
      name: name, email: email, status: 'pending', phone: phone));
  }

  @override
  Future<ClientOverview> clientOverview() async => ClientOverview(
    _projects.where((p) => _access[p.id]?.contains(_currentDemoClientId) ?? false).toList(),
    _clientRequests.where((r) => _requestOwners[r.id] == _currentDemoClientId).toList(),
    _clientRequests.where((r) => _requestOwners[r.id] == _currentDemoClientId &&
      r.status != 'resuelta' && r.status != 'rechazada').length,
  );

  @override
  Future<List<ClientUpdate>> clientProjectUpdates(int projectId) async {
    if (!(_access[projectId]?.contains(_currentDemoClientId) ?? false)) {
      throw Exception('No tienes acceso a esta construcción');
    }
    return _updates.where((u) => u.projectId == projectId && u.visibleToClient).toList();
  }

  @override
  Future<ClientRequestItem> createClientRequest(Map<String, dynamic> data) async {
    final projectId = data['project_id'] as int?;
    if (projectId != null && !(_access[projectId]?.contains(_currentDemoClientId) ?? false)) {
      throw Exception('No tienes acceso a esta construcción');
    }
    final project = projectId == null ? null : _projects.firstWhere((p) => p.id == projectId);
    final id = _clientRequests.isEmpty ? 1 : _clientRequests.last.id + 1;
    final item = ClientRequestItem(id: id, code: 'SOL-2026-${id.toString().padLeft(6, '0')}',
      projectId: projectId, projectName: project?.name, requesterName: 'Cliente Demostración',
      category: data['category'] as String, subject: data['subject'] as String,
      description: data['description'] as String, status: 'recibida', createdAt: DateTime.now());
    _clientRequests.add(item);
    _requestOwners[item.id] = _currentDemoClientId;
    return item;
  }

  @override
  Future<List<PortalMessage>> portalMessages(int requestId, {bool staff = false}) async {
    if (!staff && _requestOwners[requestId] != _currentDemoClientId) {
      throw Exception('Solicitud no encontrada');
    }
    return List.unmodifiable(_messages[requestId] ?? []);
  }

  @override
  Future<void> sendPortalMessage(int requestId, String body, {bool staff = false}) async {
    if (!staff && _requestOwners[requestId] != _currentDemoClientId) {
      throw Exception('Solicitud no encontrada');
    }
    _messages.putIfAbsent(requestId, () => []).add(PortalMessage(
      id: (_messages[requestId]?.length ?? 0) + 1,
      author: staff ? 'Administrador Demo' : 'Cliente Demostración',
      role: staff ? 'admin' : 'cliente', body: body, createdAt: DateTime.now()));
  }

  @override
  Future<List<PortalClient>> staffClients() async => List.unmodifiable(_clients);

  @override
  Future<void> reviewClient(int clientId, String decision) async {
    final i = _clients.indexWhere((u) => u.id == clientId);
    final old = _clients[i];
    _clients[i] = PortalClient(id: old.id, name: old.name, email: old.email,
      phone: old.phone, status: decision, supportPlan: old.supportPlan);
  }

  @override
  Future<List<ClientProject>> staffProjects() async => List.unmodifiable(_projects);

  @override
  Future<ClientProject> staffCreateProject(Map<String, dynamic> data) async {
    final id = _projects.length + 1;
    final project = ClientProject(id: id, code: 'OBR-2026-${id.toString().padLeft(6, '0')}',
      name: data['name'] as String, address: data['address'] as String?,
      summary: data['customer_summary'] as String?, status: 'planificacion', progress: 0);
    _projects.add(project);
    return project;
  }

  @override
  Future<ClientProject> staffEditProject(int projectId, Map<String, dynamic> data) async {
    final i = _projects.indexWhere((p) => p.id == projectId);
    final old = _projects[i];
    final update = ClientProject(id: old.id, code: old.code, name: old.name,
      status: data['status'] as String? ?? old.status,
      progress: data['progress_percent'] as int? ?? old.progress,
      summary: data.containsKey('customer_summary') ? data['customer_summary'] as String? : old.summary,
      address: old.address, startDate: old.startDate, estimatedEnd: old.estimatedEnd);
    _projects[i] = update;
    return update;
  }

  @override
  Future<List<ClientUpdate>> staffProjectUpdates(int projectId) async =>
    _updates.where((u) => u.projectId == projectId).toList();

  @override
  Future<void> staffPostProjectUpdate(int projectId, String title, String detail, bool visible) async {
    _updates.insert(0, ClientUpdate(id: _updates.length + 1, projectId: projectId,
      title: title, detail: detail, visibleToClient: visible, createdAt: DateTime.now()));
  }

  @override
  Future<List<ProjectAccess>> staffProjectClients(int projectId) async =>
    _clients.where((c) => _access[projectId]?.contains(c.id) ?? false)
      .map((c) => ProjectAccess(userId: c.id, name: c.name, email: c.email, active: true)).toList();

  @override
  Future<void> staffGrantProjectAccess(int projectId, int clientId) async {
    _access.putIfAbsent(projectId, () => <int>{}).add(clientId);
  }

  @override
  Future<void> staffChangeProjectAccess(int projectId, int clientId, bool active) async {
    if (active) { _access.putIfAbsent(projectId, () => <int>{}).add(clientId); }
    else { _access[projectId]?.remove(clientId); }
  }

  @override
  Future<List<ClientRequestItem>> staffRequests() async => List.unmodifiable(_clientRequests);

  @override
  Future<void> staffChangeRequestStatus(int requestId, String status) async {
    final i = _clientRequests.indexWhere((r) => r.id == requestId);
    final old = _clientRequests[i];
    _clientRequests[i] = ClientRequestItem(id: old.id, code: old.code,
      projectId: old.projectId, projectName: old.projectName, requesterName: old.requesterName,
      category: old.category, subject: old.subject, description: old.description,
      status: status, createdAt: old.createdAt);
  }
  // Los eventos de demostración son ficticios; la API real utiliza WebSocket.
  final Map<int, SupportThread> _supportThreads = {
    101: SupportThread(id: 1, customerId: 101,
      customerName: 'Cliente Suscrito Demo', customerEmail: 'cliente@demo.local',
      plan: 'suscrito', priority: 'normal', status: 'abierta',
      updatedAt: DateTime(2026, 11, 14, 10, 15)),
    103: SupportThread(id: 2, customerId: 103,
      customerName: 'Cliente Plus Demo', customerEmail: 'plus@demo.local',
      plan: 'plus', priority: 'plus', status: 'abierta',
      updatedAt: DateTime(2026, 11, 14, 11, 20)),
  };
  final Map<int, List<SupportChatMessage>> _supportMessages = {
    1: [SupportChatMessage(id: 1, conversationId: 1, authorId: 101,
      authorName: 'Cliente Suscrito Demo', authorRole: 'cliente',
      body: 'Hola, quisiera consultar el avance de mi proyecto.',
      createdAt: DateTime(2026, 11, 14, 9, 40)),
      SupportChatMessage(id: 2, conversationId: 1, authorId: 1,
      authorName: 'Equipo Obratek', authorRole: 'admin',
      body: '¡Hola! Revisaremos tu consulta y te responderemos.',
      createdAt: DateTime(2026, 11, 14, 10, 15))],
    2: [SupportChatMessage(id: 3, conversationId: 2, authorId: 103,
      authorName: 'Cliente Plus Demo', authorRole: 'cliente',
      body: 'Necesito coordinación prioritaria de una visita.',
      createdAt: DateTime(2026, 11, 14, 11, 20))],
  };

  SupportThread _withPlan(SupportThread t) {
    final client = _clients.firstWhere((x) => x.id == t.customerId);
    return SupportThread(id: t.id, customerId: t.customerId,
      customerName: client.name, customerEmail: client.email,
      plan: client.supportPlan,
      priority: client.supportPlan == 'plus' ? 'plus' : 'normal',
      status: t.status, updatedAt: t.updatedAt);
  }

  @override
  Future<SupportOverview> clientSupport() async {
    final client = _clients.firstWhere((x) => x.id == _currentDemoClientId);
    final thread = _supportThreads[_currentDemoClientId];
    return SupportOverview(plan: client.supportPlan,
      enabled: client.supportPlan == 'plus' || client.supportPlan == 'suscrito',
      thread: thread == null ? null : _withPlan(thread),
      messages: List.unmodifiable(_supportMessages[thread?.id] ?? []));
  }

  @override
  Future<SupportThread> openClientSupport() async {
    final client = _clients.firstWhere((x) => x.id == _currentDemoClientId);
    if (client.supportPlan == 'no_suscrito') throw Exception('Este plan no incluye chat en vivo');
    final old = _supportThreads[client.id];
    if (old != null) return _withPlan(old);
    final id = (_supportThreads.values.map((x) => x.id).fold<int>(0,
      (max, id) => id > max ? id : max)) + 1;
    final created = SupportThread(id: id, customerId: client.id,
      customerName: client.name, customerEmail: client.email,
      plan: client.supportPlan, priority: client.supportPlan == 'plus' ? 'plus' : 'normal',
      status: 'abierta', updatedAt: DateTime.now());
    _supportThreads[client.id] = created;
    return created;
  }

  @override
  Future<void> sendClientSupport(String body) async {
    final thread = await openClientSupport();
    if (thread.status == 'cerrada') throw Exception('Conversación cerrada');
    _supportMessages.putIfAbsent(thread.id, () => []).add(SupportChatMessage(
      id: (_supportMessages[thread.id]?.length ?? 0) + 50,
      conversationId: thread.id, authorId: _currentDemoClientId,
      authorName: thread.customerName, authorRole: 'cliente',
      body: body, createdAt: DateTime.now()));
  }

  @override
  Future<List<SupportThread>> staffSupportInbox() async {
    final values = _supportThreads.values.map(_withPlan).toList();
    values.sort((a,b) {
      if ((a.plan == 'plus') != (b.plan == 'plus')) {
        return a.plan == 'plus' ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return values;
  }

  @override
  Future<SupportThreadDetail> staffSupportDetail(int threadId) async {
    final thread = _supportThreads.values.firstWhere((x) => x.id == threadId);
    return SupportThreadDetail(_withPlan(thread),
      List.unmodifiable(_supportMessages[threadId] ?? []));
  }

  @override
  Future<void> staffSupportReply(int threadId, String body) async {
    final thread = _supportThreads.values.firstWhere((x) => x.id == threadId);
    if (thread.status == 'cerrada') throw Exception('Conversación cerrada');
    _supportMessages.putIfAbsent(threadId, () => []).add(SupportChatMessage(
      id: (_supportMessages[threadId]?.length ?? 0) + 60,
      conversationId: threadId, authorId: 1, authorName: 'Equipo Obratek',
      authorRole: 'admin', body: body, createdAt: DateTime.now()));
  }

  @override
  Future<void> staffSupportStatus(int threadId, String status) async {
    final thread = _supportThreads.values.firstWhere((x) => x.id == threadId);
    _supportThreads[thread.customerId] = SupportThread(id: thread.id,
      customerId: thread.customerId, customerName: thread.customerName,
      customerEmail: thread.customerEmail, plan: thread.plan,
      priority: thread.priority, status: status, updatedAt: DateTime.now());
  }

  @override
  Future<void> staffSupportPlan(int clientId, String plan) async {
    final index = _clients.indexWhere((x) => x.id == clientId);
    if (index < 0) throw Exception('Cliente no encontrado');
    final old = _clients[index];
    _clients[index] = PortalClient(id: old.id, name: old.name, email: old.email,
      status: old.status, phone: old.phone, supportPlan: plan);
  }

  @override
  Stream<int> supportEvents(int conversationId) => const Stream<int>.empty();

}
