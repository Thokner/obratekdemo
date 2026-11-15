import 'package:flutter/material.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';

class ModulePage extends StatefulWidget {
  final String title;
  final String kind;
  final ObratekRepository repository;
  final UserSession user;
  final bool embedded;
  const ModulePage({super.key, required this.title,
    required this.kind, required this.repository, required this.user,
    this.embedded = false});
  @override
  State<ModulePage> createState() => _ModulePageState();
}

class _ModulePageState extends State<ModulePage> {
  late Future<dynamic> data = _load();
  Future<dynamic> _load() {
    if (widget.kind == 'quotes') return widget.repository.quotes();
    if (widget.kind == 'activities') return widget.repository.activities();
    if (const ['workers', 'companies', 'contacts', 'properties', 'services']
        .contains(widget.kind)) return widget.repository.catalog(widget.kind);
    return Future.value(null);
  }

  Future<void> addEntry() async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(context: context, builder: (dialogContext) =>
      AlertDialog(title: Text('Nuevo registro: ${widget.title}'),
        content: TextField(controller: controller, autofocus: true,
          maxLength: 180,
          decoration: const InputDecoration(labelText: 'Nombre',
            hintText: 'Nombre del registro')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            if (controller.text.trim().length < 2) return;
            try {
              await widget.repository.addCatalog(widget.kind, controller.text.trim());
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            } catch (e) {
              if (dialogContext.mounted) showSnack(dialogContext, '$e', error: true);
            }
          }, child: const Text('Guardar')),
        ],
      ));
    controller.dispose();
    if (created == true && mounted) setState(() => data = _load());
  }

  @override
  Widget build(BuildContext context) {
    final content = ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageTitle(eyebrow: 'Administración', title: widget.title,
            subtitle: widget.kind == 'all' ?
              'Catálogos y módulos adicionales de la aplicación.' :
              'Registros del módulo. Los campos avanzados se sumarán luego de validar AppSheet.',
            trailing: widget.user.canEdit &&
              const ['workers', 'companies', 'contacts', 'properties', 'services']
                .contains(widget.kind) ? ElevatedButton.icon(
                  onPressed: addEntry, icon: const Icon(Icons.add),
                  label: const Text('Nuevo registro')) : null),
          const SizedBox(height: 23),
          if (widget.kind == 'all') ...[
            for (final module in [
              ('Cotizaciones', 'quotes', Icons.request_quote_outlined),
              ('Trabajadores', 'workers', Icons.badge_outlined),
              ('Empresas', 'companies', Icons.apartment_outlined),
              ('Contactos', 'contacts', Icons.contact_page_outlined),
              ('Inmuebles', 'properties', Icons.location_city_outlined),
              ('Servicios', 'services', Icons.design_services_outlined),
              ('Actividades', 'activities', Icons.checklist_rounded),
              ('Materiales y compras', 'materials', Icons.shopping_cart_outlined),
              ('Finanzas', 'finances', Icons.account_balance_wallet_outlined),
              ('SII y exportaciones', 'sii', Icons.receipt_long_outlined),
            ]) ...[
              SectionSurface(padding: EdgeInsets.zero, child: ListTile(
                leading: Icon(module.$3, color: AppPalette.primary),
                title: Text(module.$1),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ModulePage(title: module.$1,
                    kind: module.$2, repository: widget.repository, user: widget.user))),
              )),
              const SizedBox(height: 9),
            ],
          ] else if (widget.kind == 'materials' || widget.kind == 'finances' ||
                     widget.kind == 'sii') ...[
            const SectionSurface(child: EmptyNotice(
              title: 'Módulo identificado en el informe',
              detail: 'Las tablas y acciones existen en AppSheet, pero todavía faltan sus campos completos, reglas y validaciones antes de habilitar formularios reales.',
              icon: Icons.rule_folder_outlined)),
          ] else ...[
            AsyncPanel<dynamic>(future: data, onRetry: () => setState(() => data = _load()),
              builder: (items) {
                final list = items as List;
                if (list.isEmpty) return const SectionSurface(child: EmptyNotice(
                  title: 'Todavía no hay registros',
                  detail: 'Importaremos los registros actuales cuando validemos la exportación.'));
                return Column(children: [
                  for (final item in list) ...[
                    SectionSurface(padding: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: AppPalette.primarySoft,
                          child: const Icon(Icons.description_outlined,
                            color: AppPalette.primary, size: 21)),
                        title: Text(item is CatalogItem ? item.name :
                            item is QuoteInfo ? '${item.code} · ${item.client}' :
                            '${(item as Map<String, dynamic>)['title']}'),
                        subtitle: item is QuoteInfo ?
                            Text('Estado: ${statusLabel(item.status)}') : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ]);
              }),
          ],
        ]),
      )),
    ]);
    return widget.embedded ? content : Scaffold(
      appBar: AppBar(title: Text(widget.title)), body: content);
  }
}
