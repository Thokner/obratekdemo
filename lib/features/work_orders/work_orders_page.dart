import 'package:flutter/material.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';
import 'order_dialogs.dart';

class WorkOrdersPage extends StatefulWidget {
  final ObratekRepository repository;
  final UserSession user;
  final VoidCallback onNewOrder;
  const WorkOrdersPage({super.key, required this.repository,
    required this.user, required this.onNewOrder});
  @override
  State<WorkOrdersPage> createState() => _WorkOrdersPageState();
}

class _WorkOrdersPageState extends State<WorkOrdersPage> {
  late Future<List<WorkOrder>> future = widget.repository.workOrders();
  final search = TextEditingController();
  String filter = 'todas';
  void reload() => setState(() => future = widget.repository.workOrders());

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async { reload(); await future; },
    child: ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageTitle(eyebrow: 'Operaciones', title: 'Proyectos y órdenes',
            subtitle: 'Controla cada orden desde su creación hasta su cierre.',
            trailing: widget.user.canEdit ? ElevatedButton.icon(
              onPressed: widget.onNewOrder,
              icon: const Icon(Icons.add_rounded), label: const Text('Nueva orden')) : null),
          const SizedBox(height: 22),
          SectionSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por OT, proyecto o descripción...',
                suffixIcon: search.text.isNotEmpty ? IconButton(
                  onPressed: () => setState(() => search.clear()),
                  icon: const Icon(Icons.close)) : null)),
            const SizedBox(height: 14),
            SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final option in [
                  ('todas', 'Todas'), ('iniciada', 'Iniciadas'),
                  ('en_ejecucion', 'En ejecución'),
                  ('finalizada', 'Finalizadas'), ('descartada', 'Descartadas')
                ]) ...[
                  ChoiceChip(label: Text(option.$2), selected: filter == option.$1,
                    onSelected: (_) => setState(() => filter = option.$1),
                    selectedColor: AppPalette.primarySoft,
                    showCheckmark: false),
                  const SizedBox(width: 9),
                ],
              ]),
            ),
          ])),
          const SizedBox(height: 17),
          AsyncPanel<List<WorkOrder>>(future: future, onRetry: reload,
            builder: (orders) {
              final query = search.text.toLowerCase().trim();
              final visible = orders.where((item) =>
                  (filter == 'todas' || item.status == filter) &&
                  (query.isEmpty || item.code.toLowerCase().contains(query) ||
                    item.description.toLowerCase().contains(query) ||
                    (item.company ?? item.contact ?? '').toLowerCase().contains(query))).toList();
              if (visible.isEmpty) return const SectionSurface(
                child: EmptyNotice(title: 'No hay órdenes para mostrar',
                  detail: 'Modifica los filtros o crea tu primera orden.',
                  icon: Icons.assignment_outlined));
              return Column(children: [
                for (final item in visible) ...[
                  _OrderCard(order: item, onTap: () async {
                    final changed = await showOrderDetailDialog(context, item,
                      widget.repository, widget.user);
                    if (changed) reload();
                  }),
                  const SizedBox(height: 11),
                ],
              ]);
            }),
          const SizedBox(height: 20),
        ]),
      )),
    ]),
  );
}

class _OrderCard extends StatelessWidget {
  final WorkOrder order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(17),
    color: Colors.white,
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17),
      child: Container(padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          border: Border.all(color: AppPalette.border),
          borderRadius: BorderRadius.circular(17)),
        child: LayoutBuilder(builder: (context, c) {
          final label = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order.code, style: const TextStyle(color: AppPalette.primary,
              fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(order.description, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w700, color: AppPalette.ink)),
            const SizedBox(height: 10),
            Wrap(spacing: 14, runSpacing: 6, children: [
              if (order.company != null || order.contact != null)
                _Meta(Icons.business_outlined, order.company ?? order.contact!),
              if (order.worker != null) _Meta(Icons.person_outline, order.worker!),
              _Meta(Icons.event_outlined, displayDate(order.createdAt)),
            ]),
          ]);
          if (c.maxWidth < 550) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              label, const SizedBox(height: 12),
              Row(children: [StatusPill(order.status), const Spacer(),
                const Icon(Icons.chevron_right, color: AppPalette.muted)]),
            ]);
          }
          return Row(children: [
            Container(width: 43, height: 43,
              decoration: BoxDecoration(color: AppPalette.primarySoft,
                borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.assignment_rounded, color: AppPalette.primary)),
            const SizedBox(width: 17),
            Expanded(child: label),
            const SizedBox(width: 12),
            StatusPill(order.status),
            const SizedBox(width: 13),
            const Icon(Icons.chevron_right, color: AppPalette.muted),
          ]);
        }),
      ),
    ),
  );
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String value;
  const _Meta(this.icon, this.value);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: AppPalette.muted),
    const SizedBox(width: 4),
    Text(value, style: const TextStyle(color: AppPalette.muted, fontSize: 11)),
  ]);
}
