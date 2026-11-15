import 'package:flutter/material.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';

Future<bool> showCreateOrderDialog(BuildContext context, ObratekRepository repo) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => _CreateOrderDialog(repository: repo),
  );
  return result ?? false;
}

class _CreateOrderDialog extends StatefulWidget {
  final ObratekRepository repository;
  const _CreateOrderDialog({required this.repository});
  @override
  State<_CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<_CreateOrderDialog> {
  final keyForm = GlobalKey<FormState>();
  final description = TextEditingController();
  late final Future<List<List<CatalogItem>>> catalogs = Future.wait([
    widget.repository.catalog('companies'), widget.repository.catalog('properties'),
    widget.repository.catalog('services'), widget.repository.catalog('workers'),
    widget.repository.catalog('contacts'),
  ]);
  String ownerType = 'empresa';
  int? companyId;
  int? contactId;
  int? propertyId;
  int? serviceId;
  int? workerId;
  bool saving = false;

  Future<void> save() async {
    if (!(keyForm.currentState?.validate() ?? false)) return;
    if ((ownerType == 'empresa' && companyId == null) ||
        (ownerType == 'contacto' && contactId == null)) {
      showSnack(context, 'Selecciona el propietario de la OT', error: true);
      return;
    }
    setState(() => saving = true);
    try {
      await widget.repository.createOrder({
        'description': description.text.trim(),
        'owner_type': ownerType,
        'company_id': ownerType == 'empresa' ? companyId : null,
        'contact_id': ownerType == 'contacto' ? contactId : null,
        'property_id': propertyId,
        'service_id': serviceId,
        'assigned_worker_id': workerId,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget picker(String label, List<CatalogItem> data,
      int? selected, ValueChanged<int?> onChange) => DropdownButtonFormField<int>(
    key: ValueKey(label),
    initialValue: selected,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      const DropdownMenuItem<int>(value: null, child: Text('Sin seleccionar')),
      for (final x in data) DropdownMenuItem(value: x.id,
        child: Text(x.name, overflow: TextOverflow.ellipsis)),
    ],
    onChanged: onChange,
  );

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620),
      child: Padding(padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(child: Form(key: keyForm,
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.post_add_rounded, color: AppPalette.primary),
                const SizedBox(width: 10),
                Expanded(child: Text('Nueva orden de trabajo',
                  style: Theme.of(context).textTheme.titleLarge)),
                IconButton(onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),
              const Text('La numeración se asigna en el servidor. Los datos son compartidos en todos los equipos.',
                style: TextStyle(color: AppPalette.muted, fontSize: 12)),
              const SizedBox(height: 22),
              TextFormField(controller: description, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripción del trabajo *',
                  hintText: 'Describe la tarea de forma clara...'),
                validator: (value) => value == null || value.trim().length < 5 ?
                    'Describe el trabajo (mínimo 5 caracteres)' : null),
              const SizedBox(height: 16),
              FutureBuilder<List<List<CatalogItem>>>(future: catalogs,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: snapshot.hasError
                      ? Text('No se cargaron los catálogos: ${snapshot.error}')
                      : const LinearProgressIndicator());
                  final list = snapshot.data!;
                  return Column(children: [
                    DropdownButtonFormField<String>(initialValue: ownerType,
                      decoration: const InputDecoration(labelText: 'Tipo de propietario'),
                      items: const [
                        DropdownMenuItem(value: 'empresa', child: Text('Empresa')),
                        DropdownMenuItem(value: 'contacto', child: Text('Contacto')),
                      ],
                      onChanged: (v) => setState(() => ownerType = v ?? 'empresa')),
                    const SizedBox(height: 14),
                    if (ownerType == 'empresa')
                      picker('Empresa propietaria *', list[0], companyId,
                        (v) => setState(() => companyId = v))
                    else
                      picker('Contacto propietario *', list[4], contactId,
                        (v) => setState(() => contactId = v)),
                    const SizedBox(height: 14),
                    picker('Inmueble', list[1], propertyId,
                      (v) => setState(() => propertyId = v)),
                    const SizedBox(height: 14),
                    picker('Servicio', list[2], serviceId,
                      (v) => setState(() => serviceId = v)),
                    const SizedBox(height: 14),
                    picker('Trabajador asignado', list[3], workerId,
                      (v) => setState(() => workerId = v)),
                  ]);
                }),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: saving ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancelar'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Guardando...' : 'Crear orden'))),
              ]),
            ],
          ),
        )),
      ),
    ),
  );
}

Future<bool> showOrderDetailDialog(BuildContext context, WorkOrder order,
    ObratekRepository repo, UserSession user) async {
  return await showDialog<bool>(context: context,
    builder: (ctx) => _OrderDetailDialog(order: order, repo: repo, user: user)) ?? false;
}

class _OrderDetailDialog extends StatefulWidget {
  final WorkOrder order;
  final ObratekRepository repo;
  final UserSession user;
  const _OrderDetailDialog({required this.order, required this.repo, required this.user});
  @override
  State<_OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<_OrderDetailDialog> {
  final note = TextEditingController();
  bool busy = false;
  bool changed = false;
  late WorkOrder order = widget.order;

  Future<void> setStatus(String status) async {
    setState(() => busy = true);
    try {
      final updated = await widget.repo.changeStatus(order.id, status);
      if (mounted) setState(() { order = updated; changed = true; });
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> addNote() async {
    if (note.text.trim().length < 3) return;
    setState(() => busy = true);
    try {
      await widget.repo.addLog(order.id, note.text.trim());
      note.clear();
      changed = true;
      if (mounted) showSnack(context, 'Registro añadido a la bitácora');
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Widget statusAndNote() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Wrap(spacing: 20, runSpacing: 15, children: [
      _DetailField('Servicio', order.service ?? 'No indicado'),
      _DetailField('Responsable', order.worker ?? 'Sin asignar'),
      _DetailField('Estado', statusLabel(order.status)),
    ]),
    if (widget.user.canEdit && order.status != 'finalizada' &&
        order.status != 'descartada') ...[
      const SizedBox(height: 23),
      const Text('Actualizar estado', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Wrap(spacing: 9, runSpacing: 8, children: [
        if (order.status == 'iniciada')
          OutlinedButton.icon(onPressed: busy ? null : () => setStatus('en_ejecucion'),
            icon: const Icon(Icons.play_arrow_rounded, size: 19),
            label: const Text('Iniciar ejecución')),
        if (order.status == 'en_ejecucion')
          FilledButton.icon(onPressed: busy ? null : () => setStatus('finalizada'),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Finalizar OT')),
        OutlinedButton(onPressed: busy ? null : () => setStatus('descartada'),
          child: const Text('Descartar')),
      ]),
    ],
    if (order.status != 'finalizada' && order.status != 'descartada') ...[
      const SizedBox(height: 23),
      const Text('Agregar observación a la bitácora',
        style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      TextField(controller: note, maxLines: 3,
        decoration: const InputDecoration(hintText: 'Describe avances u observaciones...')),
      const SizedBox(height: 11),
      Align(alignment: Alignment.centerRight, child: FilledButton.icon(
        onPressed: busy ? null : addNote,
        icon: const Icon(Icons.note_add_outlined, size: 18),
        label: const Text('Guardar en bitácora'))),
    ],
  ]);

  Widget pendingSection(String title, String detail, IconData icon) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800,
        fontSize: 17)),
      const SizedBox(height: 13),
      EmptyNotice(title: 'Campos pendientes de verificación',
        detail: detail, icon: icon),
    ]);

  Widget historySection() {
    if (widget.user.role != 'admin' && widget.user.role != 'auditor') {
      return const EmptyNotice(title: 'Historial restringido',
        detail: 'Sólo los perfiles expresamente autorizados pueden consultar cambios globales.',
        icon: Icons.shield_outlined);
    }
    return AsyncPanel<List<AuditEntry>>(
      future: widget.repo.auditRecord('work_order', '${order.id}'),
      builder: (records) => records.isEmpty
        ? const EmptyNotice(title: 'Sin cambios auditados',
            detail: 'Los cambios registrados en servidor aparecerán aquí.')
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final a in records) ListTile(
            leading: const Icon(Icons.history, color: AppPalette.primary),
            title: Text(auditEventLabel(a.event)),
            subtitle: Text('${a.actorName} · ${displayDate(a.createdAt)}'),
          )]),
    );
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 880),
      child: SizedBox(height: MediaQuery.sizeOf(context).height * .79,
        child: DefaultTabController(length: 6,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(padding: const EdgeInsets.fromLTRB(22, 17, 14, 10),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.code, style: Theme.of(context).textTheme.titleLarge),
                    Text(order.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppPalette.muted)),
                  ])),
                StatusPill(order.status),
                IconButton(onPressed: () => Navigator.pop(context, changed),
                  tooltip: 'Cerrar', icon: const Icon(Icons.close)),
              ])),
            const TabBar(isScrollable: true, tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Información general'), Tab(text: 'Ejecución'),
                Tab(text: 'Ingresos y egresos'), Tab(text: 'Administración'),
                Tab(text: 'Entrega y pendientes'), Tab(text: 'Historial'),
              ]),
            Expanded(child: TabBarView(children: [
              SingleChildScrollView(padding: const EdgeInsets.all(23),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datos generales de la OT',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 19),
                    Wrap(spacing: 22, runSpacing: 19, children: [
                      _DetailField('Propietario', order.company ?? order.contact ?? 'No asignado'),
                      _DetailField('Inmueble', order.property ?? 'No asignado'),
                      _DetailField('Creada', displayDate(order.createdAt)),
                      _DetailField('Estado actual', statusLabel(order.status)),
                    ]),
                    const SizedBox(height: 24),
                    const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 7), Text(order.description),
                  ])),
              SingleChildScrollView(padding: const EdgeInsets.all(23),
                child: statusAndNote()),
              SingleChildScrollView(padding: const EdgeInsets.all(23),
                child: pendingSection('Ingresos y egresos',
                  'La auditoría confirma referencias a OT, pero no todos los campos ni permisos financieros. Este bloque se habilitará al validar la migración.',
                  Icons.receipt_long_outlined)),
              SingleChildScrollView(padding: const EdgeInsets.all(23),
                child: pendingSection('Administración',
                  'Pendiente: totales, documentos tributarios, cálculos y condiciones de edición por rol.',
                  Icons.admin_panel_settings_outlined)),
              SingleChildScrollView(padding: const EdgeInsets.all(23),
                child: pendingSection('Entrega y pendientes',
                  'Pendiente de validar: firmas, fotos, estados de entrega y lista de materiales de la orden actual.',
                  Icons.fact_check_outlined)),
              SingleChildScrollView(padding: const EdgeInsets.all(23),
                child: historySection()),
            ])),
          ])),
      ),
    ),
  );
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  const _DetailField(this.label, this.value);
  @override
  Widget build(BuildContext context) => SizedBox(width: 175,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppPalette.muted, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]),
  );
}
