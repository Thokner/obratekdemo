import 'package:flutter/material.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';

class PlanningPage extends StatefulWidget {
  final ObratekRepository repository;
  final UserSession user;
  const PlanningPage({super.key, required this.repository, required this.user});
  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  late Future<List<PlanItem>> future = widget.repository.plans();
  void reload() => setState(() => future = widget.repository.plans());

  Future<void> add() async {
    final orders = await widget.repository.workOrders();
    if (!mounted) return;
    if (orders.isEmpty) {
      showSnack(context, 'Primero debes registrar una orden de trabajo');
      return;
    }
    final result = await showDialog<bool>(context: context,
      builder: (_) => _PlanDialog(repo: widget.repository, orders: orders));
    if (result == true) reload();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async { reload(); await future; },
    child: ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageTitle(eyebrow: 'Organización de terreno', title: 'Planificación',
            subtitle: 'Programa visitas y actividades vinculadas a cada OT.',
            trailing: widget.user.canEdit ? ElevatedButton.icon(
              onPressed: add, icon: const Icon(Icons.event_available_outlined),
              label: const Text('Nueva planificación')) : null),
          const SizedBox(height: 22),
          SectionSurface(child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: AppPalette.primary),
            const SizedBox(width: 10),
            Expanded(child: Text('La integración con Google Calendar se conectará después de validar las reglas del bot original.',
              style: TextStyle(fontSize: 12, color: AppPalette.muted,
                height: 1.4))),
          ])),
          const SizedBox(height: 17),
          AsyncPanel<List<PlanItem>>(future: future, onRetry: reload,
            builder: (plans) {
              if (plans.isEmpty) return const SectionSurface(
                child: EmptyNotice(title: 'Sin planificación registrada',
                  detail: 'Crea una fecha y asígnala a una orden de trabajo.',
                  icon: Icons.event_busy_outlined));
              return Column(children: [
                for (final plan in plans) ...[
                  SectionSurface(child: Row(children: [
                    Container(width: 59, height: 59,
                      decoration: BoxDecoration(color: AppPalette.primarySoft,
                        borderRadius: BorderRadius.circular(14)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${plan.date.day}', style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 23,
                          color: AppPalette.primary)),
                        Text('${plan.date.month}/${plan.date.year}',
                          style: const TextStyle(color: AppPalette.primary,
                            fontSize: 10)),
                      ])),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(plan.description,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('${plan.code} · ${displayDate(plan.date)}',
                        style: const TextStyle(color: AppPalette.muted, fontSize: 11)),
                    ])),
                    const SizedBox(width: 8),
                    StatusPill(plan.status),
                  ])),
                  const SizedBox(height: 11),
                ],
              ]);
            }),
        ]),
      )),
    ]),
  );
}

class _PlanDialog extends StatefulWidget {
  final ObratekRepository repo;
  final List<WorkOrder> orders;
  const _PlanDialog({required this.repo, required this.orders});
  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  final description = TextEditingController();
  final formKey = GlobalKey<FormState>();
  DateTime date = DateTime.now();
  int? orderId;
  bool busy = false;

  @override
  void dispose() { description.dispose(); super.dispose(); }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false) || orderId == null) {
      showSnack(context, 'Selecciona una OT y describe la actividad', error: true);
      return;
    }
    setState(() => busy = true);
    try {
      await widget.repo.addPlan(orderId!, date, description.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(padding: const EdgeInsets.all(23),
        child: SingleChildScrollView(child: Form(key: formKey, child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Nueva planificación', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            DropdownButtonFormField<int>(initialValue: orderId, isExpanded: true,
              decoration: const InputDecoration(labelText: 'Orden de trabajo'),
              items: widget.orders.where((o) => o.status != 'finalizada' &&
                  o.status != 'descartada')
                .map((o) => DropdownMenuItem(value: o.id,
                  child: Text('${o.code} · ${o.description}',
                    overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (value) => setState(() => orderId = value)),
            const SizedBox(height: 13),
            OutlinedButton.icon(onPressed: () async {
              final picked = await showDatePicker(context: context,
                initialDate: date, firstDate: DateTime(2020),
                lastDate: DateTime(2100));
              if (picked != null) setState(() => date = picked);
            }, icon: const Icon(Icons.calendar_month),
              label: Text('Fecha: ${displayDate(date)}')),
            const SizedBox(height: 13),
            TextFormField(controller: description, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: (value) => (value?.trim().length ?? 0) < 3 ?
                  'Describe la planificación' : null),
            const SizedBox(height: 21),
            ElevatedButton(onPressed: busy ? null : save,
              child: Text(busy ? 'Guardando...' : 'Guardar planificación')),
          ],
        ))),
      ),
    ),
  );
}
