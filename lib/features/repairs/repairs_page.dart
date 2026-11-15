import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ob_ui.dart';

class RepairsPage extends StatelessWidget {
  const RepairsPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20), children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const PageTitle(eyebrow: 'Operaciones', title: 'Reparación',
            subtitle: 'Espacio reservado para el flujo de reparaciones de Obratek.'),
          const SizedBox(height: 25),
          const SectionSurface(child: EmptyNotice(
            title: 'Estructura por validar con AppSheet',
            detail: 'El informe muestra una vista Reparación que utiliza “Orden de Reparacion”, pero esa fuente no está confirmada entre las 34 tablas físicas. Antes de implementarla debemos revisar sus datos y acciones.',
            icon: Icons.build_circle_outlined)),
          const SizedBox(height: 17),
          Container(padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(color: AppPalette.primarySoft,
              borderRadius: BorderRadius.circular(15)),
            child: const Row(children: [
              Icon(Icons.fact_check_outlined, color: AppPalette.primary),
              SizedBox(width: 10),
              Expanded(child: Text('No se inventaron formularios ni procesos de reparación que el informe no confirma.',
                style: TextStyle(color: AppPalette.primary, fontSize: 12))),
            ])),
        ]),
      )),
    ],
  );
}
