import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import 'repository.dart';

class ApiRepository implements ObratekRepository {
  String? _token;
  final http.Client _client = http.Client();

  Future<dynamic> _request(String method, String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('${AppConfig.apiBase}$path');
    final headers = <String, String>{'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token'};
    late http.Response response;
    try {
      if (method == 'GET') {
        response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      } else if (method == 'POST') {
        response = await _client.post(uri, headers: headers,
            body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 15));
      } else if (method == 'PATCH') {
        response = await _client.patch(uri, headers: headers,
            body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 15));
      } else {
        throw StateError('Método no admitido');
      }
    } catch (_) {
      throw Exception('No se pudo conectar con el servidor. Revisa la API y tu red.');
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode >= 400) {
      final detail = decoded is Map ? decoded['detail'] : null;
      if (response.statusCode == 401) {
        _token = null;
      }
      throw Exception(detail is String ? detail : 'Error ${response.statusCode} del servidor');
    }
    return decoded;
  }

  @override
  Future<UserSession> login(String email, String password) async {
    final data = await _request('POST', '/auth/login',
        {'email': email, 'password': password}) as Map<String, dynamic>;
    _token = data['access_token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    return UserSession(user['name'] as String, user['email'] as String,
        user['role'] as String, customerStatus: user['customer_status'] as String? ?? 'approved',
        supportPlan: user['support_plan'] as String? ?? 'no_suscrito');
  }

  @override
  Future<DashboardSummary> summary() async =>
      DashboardSummary.fromJson(await _request('GET', '/dashboard/summary') as Map<String, dynamic>);

  @override
  Future<List<WorkOrder>> workOrders() async =>
      (await _request('GET', '/work-orders') as List).map((e) =>
          WorkOrder.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<WorkOrder> createOrder(Map<String, dynamic> data) async =>
      WorkOrder.fromJson(await _request('POST', '/work-orders', data) as Map<String, dynamic>);

  @override
  Future<WorkOrder> changeStatus(int id, String status) async =>
      WorkOrder.fromJson(await _request('PATCH', '/work-orders/$id/status',
          {'status': status}) as Map<String, dynamic>);

  @override
  Future<List<LogEntry>> logs() async =>
      (await _request('GET', '/work-logs') as List).map((e) =>
          LogEntry.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<void> addLog(int orderId, String description) async {
    await _request('POST', '/work-orders/$orderId/logs', {'description': description});
  }

  @override
  Future<List<PlanItem>> plans() async =>
      (await _request('GET', '/planning') as List).map((e) =>
          PlanItem.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<void> addPlan(int orderId, DateTime day, String description) async {
    final value = '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    await _request('POST', '/planning', {
      'work_order_id': orderId, 'scheduled_date': value,
      'description': description,
    });
  }

  @override
  Future<List<CatalogItem>> catalog(String kind) async =>
      (await _request('GET', '/catalog/$kind') as List).map((e) =>
          CatalogItem.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<CatalogItem> addCatalog(String kind, String name) async =>
      CatalogItem.fromJson(await _request('POST', '/catalog/$kind',
          {'name': name}) as Map<String, dynamic>);

  @override
  Future<List<QuoteInfo>> quotes() async =>
      (await _request('GET', '/quotes') as List).map((e) =>
          QuoteInfo.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<List<Map<String, dynamic>>> activities() async =>
      (await _request('GET', '/activities') as List)
          .map((e) => e as Map<String, dynamic>).toList();

  @override
  Future<List<AuditEntry>> auditEvents({String? entity, String? event,
    String? entityId, int? actorId, DateTime? since, DateTime? until}) async {
    final q = <String, String>{
      if (entity != null && entity.isNotEmpty) 'entity': entity,
      if (event != null && event.isNotEmpty) 'event': event,
      if (entityId != null && entityId.isNotEmpty) 'entity_id': entityId,
      if (actorId != null) 'actor_id': '$actorId',
      if (since != null) 'since': since.toUtc().toIso8601String(),
      if (until != null) 'until': until.toUtc().toIso8601String(),
    };
    final path = q.isEmpty ? '/audit' : '/audit?${Uri(queryParameters: q).query}';
    return (await _request('GET', path) as List)
      .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<AuditEntry>> auditRecord(String entity, String entityId) async =>
    (await _request('GET', '/audit/record/${Uri.encodeComponent(entity)}/${Uri.encodeComponent(entityId)}') as List)
      .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>)).toList();

  @override
  void logout() => _token = null;

  @override
  Future<void> registerClient(String name, String email, String password, String phone) async {
    await _request('POST', '/auth/client-register', {
      'name': name, 'email': email, 'password': password, 'phone': phone,
    });
  }

  @override
  Future<ClientOverview> clientOverview() async => ClientOverview.fromJson(
    await _request('GET', '/client/overview') as Map<String, dynamic>);

  @override
  Future<List<ClientUpdate>> clientProjectUpdates(int projectId) async =>
    (await _request('GET', '/client/projects/$projectId/updates') as List)
      .map((e) => ClientUpdate.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<ClientRequestItem> createClientRequest(Map<String, dynamic> data) async =>
    ClientRequestItem.fromJson(await _request('POST', '/client/requests', data) as Map<String, dynamic>);

  @override
  Future<List<PortalMessage>> portalMessages(int requestId, {bool staff = false}) async =>
    (await _request('GET', '/${staff ? 'staff' : 'client'}/requests/$requestId/messages') as List)
      .map((e) => PortalMessage.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<void> sendPortalMessage(int requestId, String body, {bool staff = false}) async {
    await _request('POST', '/${staff ? 'staff' : 'client'}/requests/$requestId/messages', {'body': body});
  }

  @override
  Future<List<PortalClient>> staffClients() async =>
    (await _request('GET', '/staff/clients') as List)
      .map((e) => PortalClient.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<void> reviewClient(int clientId, String decision) async {
    await _request('PATCH', '/staff/clients/$clientId/review', {'status': decision});
  }

  @override
  Future<List<ClientProject>> staffProjects() async =>
    (await _request('GET', '/staff/projects') as List)
      .map((e) => ClientProject.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<ClientProject> staffCreateProject(Map<String, dynamic> data) async =>
    ClientProject.fromJson(await _request('POST', '/staff/projects', data) as Map<String, dynamic>);

  @override
  Future<ClientProject> staffEditProject(int projectId, Map<String, dynamic> data) async =>
    ClientProject.fromJson(await _request('PATCH', '/staff/projects/$projectId', data) as Map<String, dynamic>);

  @override
  Future<List<ClientUpdate>> staffProjectUpdates(int projectId) async =>
    (await _request('GET', '/staff/projects/$projectId/updates') as List)
      .map((e) => ClientUpdate.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<void> staffPostProjectUpdate(int projectId, String title, String detail, bool visible) async {
    await _request('POST', '/staff/projects/$projectId/updates', {
      'title': title, 'detail': detail, 'visible_to_client': visible,
    });
  }

  @override
  Future<List<ProjectAccess>> staffProjectClients(int projectId) async =>
    (await _request('GET', '/staff/projects/$projectId/clients') as List)
      .map((e) => ProjectAccess.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<void> staffGrantProjectAccess(int projectId, int clientId) async {
    await _request('POST', '/staff/projects/$projectId/clients', {'client_user_id': clientId});
  }

  @override
  Future<void> staffChangeProjectAccess(int projectId, int clientId, bool active) async {
    await _request('PATCH', '/staff/projects/$projectId/clients/$clientId', {'active': active});
  }

  @override
  Future<List<ClientRequestItem>> staffRequests() async =>
    (await _request('GET', '/staff/requests') as List)
      .map((e) => ClientRequestItem.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<void> staffChangeRequestStatus(int requestId, String status) async {
    await _request('PATCH', '/staff/requests/$requestId/status', {'status': status});
  }
  @override
  Future<SupportOverview> clientSupport() async => SupportOverview.fromJson(
    await _request('GET', '/client/support') as Map<String, dynamic>);

  @override
  Future<SupportThread> openClientSupport() async => SupportThread.fromJson(
    await _request('POST', '/client/support/open') as Map<String, dynamic>);

  @override
  Future<void> sendClientSupport(String body) async {
    await _request('POST', '/client/support/messages', {'body': body});
  }

  @override
  Future<List<SupportThread>> staffSupportInbox() async =>
    (await _request('GET', '/staff/support/conversations') as List)
      .map((x) => SupportThread.fromJson(x as Map<String, dynamic>)).toList();

  @override
  Future<SupportThreadDetail> staffSupportDetail(int threadId) async =>
    SupportThreadDetail.fromJson(await _request('GET',
      '/staff/support/conversations/$threadId') as Map<String, dynamic>);

  @override
  Future<void> staffSupportReply(int threadId, String body) async {
    await _request('POST', '/staff/support/conversations/$threadId/messages', {'body': body});
  }

  @override
  Future<void> staffSupportStatus(int threadId, String status) async {
    await _request('PATCH', '/staff/support/conversations/$threadId/status', {'status': status});
  }

  @override
  Future<void> staffSupportPlan(int clientId, String plan) async {
    await _request('PATCH', '/staff/clients/$clientId/support-plan', {'plan': plan});
  }

  @override
  Stream<int> supportEvents(int conversationId) async* {
    // Una credencial websocket de 45 segundos y de un solo uso; no enviamos
    // el JWT de sesión ni contraseñas en la URL del WebSocket.
    final ticketResponse = await _request('POST', '/support/socket-ticket',
      {'conversation_id': conversationId}) as Map<String, dynamic>;
    final base = Uri.parse(AppConfig.apiBase);
    final socketUri = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '${base.path}/support/live/$conversationId',
      queryParameters: {'ticket': ticketResponse['ticket'] as String},
    );
    final channel = WebSocketChannel.connect(socketUri);
    await channel.ready;
    final heartbeat = Stream.periodic(const Duration(seconds: 25))
      .listen((_) => channel.sink.add('ping'));
    try {
      await for (final _ in channel.stream) {
        yield 1; // La UI recarga desde REST, que sigue verificando autorizaciones.
      }
    } finally {
      await heartbeat.cancel();
      await channel.sink.close();
    }
  }

}

