import 'package:flutter/material.dart';
import '../../core/data/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';

class BitacorasPage extends StatefulWidget {
  final ObratekRepository repository;
  const BitacorasPage({super.key, required this.repository});
  @override
  State<BitacorasPage> createState() => _BitacorasPageState();
}

class _BitacorasPageState extends State<BitacorasPage> {
  late Future<List<LogEntry>> future = widget.repository.logs();
  void reload() => setState(() => future = widget.repository.logs());

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async { reload(); await future; },
    child: ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageTitle(eyebrow: 'Trazabilidad', title: 'Bitácoras',
            subtitle: 'Registra avances y consulta el historial de las órdenes.',
            trailing: OutlinedButton.icon(onPressed: reload,
              icon: const Icon(Icons.refresh), label: const Text('Actualizar'))),
          const SizedBox(height: 23),
          AsyncPanel<List<LogEntry>>(future: future, onRetry: reload,
            builder: (logs) {
              if (logs.isEmpty) return const SectionSurface(
                child: EmptyNotice(title: 'Aún no hay bitácoras',
                  detail: 'Abre una orden de trabajo y añade una observación.'));
              return Column(children: [
                for (final log in logs) ...[
                  SectionSurface(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 41, height: 41,
                      decoration: BoxDecoration(color: AppPalette.primarySoft,
                        borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.edit_note_outlined,
                        color: AppPalette.primary)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(spacing: 9, runSpacing: 5, children: [
                          Text(log.code, style: const TextStyle(
                            color: AppPalette.primary, fontSize: 12,
                            fontWeight: FontWeight.w800)),
                          Text(displayDate(log.createdAt), style: const TextStyle(
                            color: AppPalette.muted, fontSize: 11)),
                        ]),
                        const SizedBox(height: 8),
                        Text(log.description,
                          style: const TextStyle(height: 1.55, fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.account_circle_outlined,
                            color: AppPalette.muted, size: 15),
                          const SizedBox(width: 5),
                          Flexible(child: Text(log.author, style: const TextStyle(
                            color: AppPalette.muted, fontSize: 11))),
                        ]),
                      ])),
                  ])),
                  const SizedBox(height: 12),
                ],
              ]);
            }),
        ]),
      )),
    ]),
  );
}
