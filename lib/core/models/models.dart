class UserSession {
  final String name;
  final String email;
  final String role;
  final String customerStatus;
  final String supportPlan;
  const UserSession(this.name, this.email, this.role,
      {this.customerStatus = "approved", this.supportPlan = "no_suscrito"});
  bool get isClient => role == "cliente";
  bool get canEdit => role == 'admin' || role == 'supervisor';
}

class DashboardSummary {
  final int total;
  final int iniciadas;
  final int enEjecucion;
  final int finalizadas;
  final int programadas;
  const DashboardSummary({required this.total, required this.iniciadas,
    required this.enEjecucion, required this.finalizadas, required this.programadas});
  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
    total: j['total'] as int? ?? 0,
    iniciadas: j['iniciadas'] as int? ?? 0,
    enEjecucion: j['en_ejecucion'] as int? ?? 0,
    finalizadas: j['finalizadas'] as int? ?? 0,
    programadas: j['programadas'] as int? ?? 0,
  );
}

class WorkOrder {
  final int id;
  final String code;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? company;
  final String? contact;
  final String? property;
  final String? service;
  final String? worker;
  const WorkOrder({required this.id, required this.code,
    required this.description, required this.status, required this.createdAt,
    this.company, this.contact, this.property, this.service, this.worker});
  factory WorkOrder.fromJson(Map<String, dynamic> j) => WorkOrder(
    id: j['id'] as int,
    code: (j['public_code'] as String?) ?? '',
    description: (j['description'] as String?) ?? '',
    status: (j['status'] as String?) ?? 'iniciada',
    createdAt: DateTime.parse(j['created_at'] as String),
    company: j['company_name'] as String?,
    contact: j['contact_name'] as String?,
    property: j['property_name'] as String?,
    service: j['service_name'] as String?,
    worker: j['worker_name'] as String?,
  );
}

class LogEntry {
  final int id;
  final int workOrderId;
  final String code;
  final String description;
  final String author;
  final DateTime createdAt;
  const LogEntry({required this.id, required this.workOrderId, required this.code,
    required this.description, required this.author, required this.createdAt});
  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(
    id: j['id'] as int, workOrderId: j['work_order_id'] as int,
    code: j['order_code'] as String? ?? '',
    description: j['description'] as String? ?? '',
    author: j['author_name'] as String? ?? 'Sin autor',
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class PlanItem {
  final int id;
  final int workOrderId;
  final String code;
  final DateTime date;
  final String description;
  final String status;
  const PlanItem({required this.id, required this.workOrderId,
    required this.code, required this.date, required this.description,
    required this.status});
  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
    id: j['id'] as int, workOrderId: j['work_order_id'] as int,
    code: j['order_code'] as String? ?? '',
    date: DateTime.parse(j['scheduled_date'] as String),
    description: j['description'] as String? ?? '',
    status: j['status'] as String? ?? 'programada',
  );
}

class CatalogItem {
  final int id;
  final String name;
  const CatalogItem(this.id, this.name);
  factory CatalogItem.fromJson(Map<String, dynamic> j) => CatalogItem(
    j['id'] as int, j['name'] as String? ?? 'Sin nombre');
}

class QuoteInfo {
  final int id;
  final String code;
  final String client;
  final String status;
  const QuoteInfo(this.id, this.code, this.client, this.status);
  factory QuoteInfo.fromJson(Map<String, dynamic> j) => QuoteInfo(
    j['id'] as int, j['code'] as String? ?? '',
    j['client_name'] as String? ?? '', j['status'] as String? ?? 'iniciada');
}

String statusLabel(String s) => switch (s) {
  'iniciada' => 'Iniciada',
  'en_ejecucion' => 'En ejecución',
  'finalizada' => 'Finalizada',
  'descartada' => 'Descartada',
  'programada' => 'Programada',
  'pendiente' => 'Pendiente',
  'en_proceso' => 'En proceso',
  'en_revision' => 'En revisión',
  'recibida' => 'Recibida',
  'resuelta' => 'Resuelta',
  'rechazada' => 'Rechazada',
  'planificacion' => 'Planificación',
  'en_construccion' => 'En construcción',
  'pausada' => 'Pausada',
  _ => s.replaceAll('_', ' '),
};

String displayDate(DateTime d) {
  final local = d.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}


class ClientProject {
  final int id;
  final String code, name, status;
  final String? address, summary;
  final int progress;
  final DateTime? startDate, estimatedEnd;
  const ClientProject({required this.id, required this.code, required this.name,
    required this.status, required this.progress, this.address, this.summary,
    this.startDate, this.estimatedEnd});
  factory ClientProject.fromJson(Map<String, dynamic> j) => ClientProject(
    id: j['id'] as int, code: j['code'] as String? ?? '',
    name: j['name'] as String? ?? '', status: j['status'] as String? ?? 'planificacion',
    progress: j['progress_percent'] as int? ?? 0,
    address: j['address'] as String?, summary: j['customer_summary'] as String?,
    startDate: j['start_date'] == null ? null : DateTime.parse(j['start_date'] as String),
    estimatedEnd: j['estimated_end_date'] == null ? null : DateTime.parse(j['estimated_end_date'] as String),
  );
}

class ClientRequestItem {
  final int id;
  final int? projectId;
  final String code, category, subject, description, status;
  final String? projectName, requesterName;
  final DateTime createdAt;
  const ClientRequestItem({required this.id, required this.code, this.projectId,
    this.projectName, this.requesterName, required this.category, required this.subject,
    required this.description, required this.status, required this.createdAt});
  factory ClientRequestItem.fromJson(Map<String, dynamic> j) => ClientRequestItem(
    id: j['id'] as int, code: j['code'] as String? ?? '',
    projectId: j['project_id'] as int?, projectName: j['project_name'] as String?,
    requesterName: j['requester_name'] as String?,
    category: j['category'] as String? ?? 'consulta',
    subject: j['subject'] as String? ?? '',
    description: j['description'] as String? ?? '',
    status: j['status'] as String? ?? 'recibida',
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class ClientOverview {
  final List<ClientProject> projects;
  final List<ClientRequestItem> requests;
  final int openRequests;
  const ClientOverview(this.projects, this.requests, this.openRequests);
  factory ClientOverview.fromJson(Map<String, dynamic> j) => ClientOverview(
    (j['projects'] as List).map((e) => ClientProject.fromJson(e as Map<String, dynamic>)).toList(),
    (j['requests'] as List).map((e) => ClientRequestItem.fromJson(e as Map<String, dynamic>)).toList(),
    j['open_request_count'] as int? ?? 0,
  );
}

class ClientUpdate {
  final int id, projectId;
  final String title, detail;
  final bool visibleToClient;
  final DateTime createdAt;
  const ClientUpdate({required this.id, required this.projectId, required this.title,
    required this.detail, required this.visibleToClient, required this.createdAt});
  factory ClientUpdate.fromJson(Map<String, dynamic> j) => ClientUpdate(
    id: j['id'] as int, projectId: j['project_id'] as int,
    title: j['title'] as String, detail: j['detail'] as String,
    visibleToClient: j['visible_to_client'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class PortalMessage {
  final int id;
  final String author, role, body;
  final DateTime createdAt;
  const PortalMessage({required this.id, required this.author, required this.role,
    required this.body, required this.createdAt});
  factory PortalMessage.fromJson(Map<String, dynamic> j) => PortalMessage(
    id: j['id'] as int, author: j['author_name'] as String? ?? 'Usuario',
    role: j['author_role'] as String? ?? 'cliente', body: j['body'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class PortalClient {
  final int id;
  final String name, email, status, supportPlan;
  final String? phone;
  const PortalClient({required this.id, required this.name, required this.email,
    required this.status, this.phone, this.supportPlan = "no_suscrito"});
  factory PortalClient.fromJson(Map<String, dynamic> j) => PortalClient(
    id: j['id'] as int, name: j['name'] as String, email: j['email'] as String,
    status: j['customer_status'] as String? ?? 'pending',
    supportPlan: j['support_plan'] as String? ?? 'no_suscrito',
    phone: j['phone'] as String?,
  );
}

class ProjectAccess {
  final int userId;
  final String name, email;
  final bool active;
  const ProjectAccess({required this.userId, required this.name,
    required this.email, required this.active});
  factory ProjectAccess.fromJson(Map<String, dynamic> j) => ProjectAccess(
    userId: j['user_id'] as int, name: j['name'] as String? ?? 'Cliente',
    email: j['email'] as String? ?? '', active: j['active'] as bool? ?? false,
  );
}

String projectStatusLabel(String value) => switch (value) {
  'planificacion' => 'Planificación',
  'en_construccion' => 'En construcción',
  'pausada' => 'Pausada',
  'finalizada' => 'Finalizada',
  _ => value,
};
String requestStatusLabel(String value) => switch (value) {
  'recibida' => 'Recibida',
  'en_revision' => 'En revisión',
  'en_proceso' => 'En proceso',
  'resuelta' => 'Resuelta',
  'rechazada' => 'Rechazada',
  _ => value.replaceAll('_', ' '),
};


class AuditEntry {
  final int id;
  final String entity, entityId, event, actorName;
  final String? actorRole, requestId;
  final DateTime createdAt;
  final Map<String, dynamic>? before, after;
  const AuditEntry({required this.id, required this.entity, required this.entityId,
    required this.event, required this.actorName, required this.createdAt,
    this.actorRole, this.requestId, this.before, this.after});
  factory AuditEntry.fromJson(Map<String, dynamic> j) => AuditEntry(
    id: j['id'] as int, entity: j['entity'] as String? ?? '',
    entityId: j['entity_id']?.toString() ?? '',
    event: j['event'] as String? ?? '',
    actorName: j['actor_name'] as String? ?? 'Usuario',
    actorRole: j['actor_role'] as String?,
    requestId: j['request_id'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    before: j['before_data'] is Map ? Map<String, dynamic>.from(j['before_data'] as Map) : null,
    after: j['after_data'] is Map ? Map<String, dynamic>.from(j['after_data'] as Map) : null,
  );
}

String auditEventLabel(String value) => switch (value) {
  'created' => 'Creó un registro',
  'status_changed' => 'Cambió el estado',
  'updated' => 'Actualizó información',
  'login_success' => 'Inició sesión',
  'approved' => 'Aprobó el acceso',
  'rejected' => 'Rechazó el acceso',
  'access_granted' => 'Asignó acceso',
  'access_revoked' => 'Revocó acceso',
  _ => value.replaceAll('_', ' '),
};

String auditEntityLabel(String value) => switch (value) {
  'work_order' => 'Orden de trabajo',
  'work_log' => 'Bitácora',
  'project' => 'Construcción',
  'client_request' => 'Solicitud de cliente',
  'client' => 'Cliente',
  'planning' => 'Planificación',
  'activity' => 'Actividad',
  'user' => 'Usuario',
  _ => value.replaceAll('_', ' '),
};


/// Clasificación administrativa, sin cobros automáticos en esta versión.
String supportPlanLabel(String value) => switch (value) {
  'plus' => 'Plus',
  'suscrito' => 'Suscrito',
  _ => 'No suscrito',
};

class SupportThread {
  final int id, customerId;
  final String customerName, customerEmail, plan, priority, status;
  final DateTime updatedAt;
  const SupportThread({required this.id, required this.customerId,
    required this.customerName, required this.customerEmail,
    required this.plan, required this.priority, required this.status,
    required this.updatedAt});
  factory SupportThread.fromJson(Map<String, dynamic> j) => SupportThread(
    id: j['id'] as int, customerId: j['customer_id'] as int,
    customerName: j['customer_name'] as String? ?? 'Cliente',
    customerEmail: j['customer_email'] as String? ?? '',
    plan: j['plan'] as String? ?? 'no_suscrito',
    priority: j['priority'] as String? ?? 'normal',
    status: j['status'] as String? ?? 'abierta',
    updatedAt: DateTime.parse(j['updated_at'] as String),
  );
}

class SupportChatMessage {
  final int id, conversationId, authorId;
  final String authorName, authorRole, body;
  final DateTime createdAt;
  const SupportChatMessage({required this.id, required this.conversationId,
    required this.authorId, required this.authorName,
    required this.authorRole, required this.body, required this.createdAt});
  factory SupportChatMessage.fromJson(Map<String, dynamic> j) => SupportChatMessage(
    id: j['id'] as int, conversationId: j['conversation_id'] as int,
    authorId: j['author_id'] as int,
    authorName: j['author_name'] as String? ?? 'Usuario',
    authorRole: j['author_role'] as String? ?? 'cliente',
    body: j['body'] as String? ?? '',
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class SupportOverview {
  final String plan;
  final bool enabled;
  final SupportThread? thread;
  final List<SupportChatMessage> messages;
  const SupportOverview({required this.plan, required this.enabled,
    this.thread, required this.messages});
  factory SupportOverview.fromJson(Map<String, dynamic> j) => SupportOverview(
    plan: j['plan'] as String? ?? 'no_suscrito',
    enabled: j['live_chat_enabled'] as bool? ?? false,
    thread: j['conversation'] is Map<String, dynamic>
      ? SupportThread.fromJson(j['conversation'] as Map<String, dynamic>) : null,
    messages: (j['messages'] as List<dynamic>? ?? const [])
      .map((x) => SupportChatMessage.fromJson(x as Map<String, dynamic>)).toList(),
  );
}

class SupportThreadDetail {
  final SupportThread thread;
  final List<SupportChatMessage> messages;
  const SupportThreadDetail(this.thread, this.messages);
  factory SupportThreadDetail.fromJson(Map<String, dynamic> j) => SupportThreadDetail(
    SupportThread.fromJson(j['conversation'] as Map<String, dynamic>),
    (j['messages'] as List<dynamic>? ?? const [])
      .map((x) => SupportChatMessage.fromJson(x as Map<String, dynamic>)).toList(),
  );
}
