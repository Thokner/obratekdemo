import '../models/models.dart';

abstract class ObratekRepository {
  /// El chat se habilita por plan en el backend, jamás solo ocultando botones.
  Future<SupportOverview> clientSupport();
  Future<SupportThread> openClientSupport();
  Future<void> sendClientSupport(String body);
  Future<List<SupportThread>> staffSupportInbox();
  Future<SupportThreadDetail> staffSupportDetail(int threadId);
  Future<void> staffSupportReply(int threadId, String body);
  Future<void> staffSupportStatus(int threadId, String status);
  Future<void> staffSupportPlan(int clientId, String plan);
  Stream<int> supportEvents(int conversationId);
  Future<List<AuditEntry>> auditEvents({String? entity, String? event,
    String? entityId, int? actorId, DateTime? since, DateTime? until});
  Future<List<AuditEntry>> auditRecord(String entity, String entityId);
  Future<UserSession> login(String email, String password);
  void logout();
  Future<void> registerClient(String name, String email, String password, String phone);
  Future<ClientOverview> clientOverview();
  Future<List<ClientUpdate>> clientProjectUpdates(int projectId);
  Future<ClientRequestItem> createClientRequest(Map<String, dynamic> data);
  Future<List<PortalMessage>> portalMessages(int requestId, {bool staff = false});
  Future<void> sendPortalMessage(int requestId, String body, {bool staff = false});
  Future<List<PortalClient>> staffClients();
  Future<void> reviewClient(int clientId, String decision);
  Future<List<ClientProject>> staffProjects();
  Future<ClientProject> staffCreateProject(Map<String, dynamic> data);
  Future<ClientProject> staffEditProject(int projectId, Map<String, dynamic> data);
  Future<List<ClientUpdate>> staffProjectUpdates(int projectId);
  Future<void> staffPostProjectUpdate(int projectId, String title, String detail, bool visible);
  Future<List<ProjectAccess>> staffProjectClients(int projectId);
  Future<void> staffGrantProjectAccess(int projectId, int clientId);
  Future<void> staffChangeProjectAccess(int projectId, int clientId, bool active);
  Future<List<ClientRequestItem>> staffRequests();
  Future<void> staffChangeRequestStatus(int requestId, String status);
  Future<DashboardSummary> summary();
  Future<List<WorkOrder>> workOrders();
  Future<WorkOrder> createOrder(Map<String, dynamic> data);
  Future<WorkOrder> changeStatus(int id, String status);
  Future<List<LogEntry>> logs();
  Future<void> addLog(int orderId, String description);
  Future<List<PlanItem>> plans();
  Future<void> addPlan(int orderId, DateTime day, String description);
  Future<List<CatalogItem>> catalog(String kind);
  Future<CatalogItem> addCatalog(String kind, String name);
  Future<List<QuoteInfo>> quotes();
  Future<List<Map<String, dynamic>>> activities();
}
