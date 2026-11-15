import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';

class SectionSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SectionSurface({super.key, required this.child,
    this.padding = const EdgeInsets.all(20)});
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppPalette.border),
      boxShadow: const [BoxShadow(color: Color(0x0F102341),
        blurRadius: 13, offset: Offset(0, 3))]),
    child: child,
  );
}

class PageTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;
  const PageTitle({super.key, required this.eyebrow, required this.title,
    required this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 1.6,
          fontWeight: FontWeight.w800, color: AppPalette.primary)),
        const SizedBox(height: 6),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: AppPalette.muted, height: 1.5)),
      ]);
      if (trailing == null) return body;
      if (c.maxWidth < 590) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          body, const SizedBox(height: 18), trailing!,
        ]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: body), const SizedBox(width: 12), trailing!,
      ]);
    });
  }
}

class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (status) {
      'finalizada' || 'resuelta' => (const Color(0xFF137A57), const Color(0xFFE6F7EF)),
      'en_ejecucion' || 'en_proceso' || 'en_construccion' => (const Color(0xFF2257D8), const Color(0xFFE9F0FF)),
      'descartada' || 'rechazada' => (const Color(0xFF9C3D49), const Color(0xFFFFEAEE)),
      'programada' => (const Color(0xFF7356B9), const Color(0xFFF2EDFF)),
      _ => (const Color(0xFF9B680B), const Color(0xFFFFF3DD)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(statusLabel(status), style: TextStyle(color: fg,
        fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String info;
  final IconData icon;
  final Color tint;
  const MetricCard({super.key, required this.title, required this.value,
    required this.info, required this.icon, required this.tint});
  @override
  Widget build(BuildContext context) => SectionSurface(
    padding: const EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(title, style: const TextStyle(color: AppPalette.muted,
          fontSize: 12, fontWeight: FontWeight.w600))),
        Container(width: 38, height: 38,
          decoration: BoxDecoration(color: tint.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: tint, size: 20)),
      ]),
      const SizedBox(height: 12),
      Text(value, style: const TextStyle(color: AppPalette.ink, fontSize: 30,
          fontWeight: FontWeight.w800, letterSpacing: -0.8)),
      const SizedBox(height: 5),
      Text(info, style: const TextStyle(color: AppPalette.muted, fontSize: 11)),
    ]),
  );
}

class EmptyNotice extends StatelessWidget {
  final String title;
  final String detail;
  final IconData icon;
  const EmptyNotice({super.key, required this.title, required this.detail,
    this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(color: AppPalette.primarySoft, shape: BoxShape.circle),
        child: Icon(icon, size: 30, color: AppPalette.primary)),
      const SizedBox(height: 12),
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6),
      Text(detail, textAlign: TextAlign.center,
        style: const TextStyle(color: AppPalette.muted, height: 1.5)),
    ]),
  );
}

class AsyncPanel<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  const AsyncPanel({super.key, required this.future, required this.builder, this.onRetry});
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(padding: EdgeInsets.all(50), child: Center(
          child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return SectionSurface(child: Column(children: [
          const Icon(Icons.wifi_off_rounded, color: AppPalette.danger, size: 34),
          const SizedBox(height: 10),
          const Text('No se pudo cargar la información',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('${snapshot.error}', textAlign: TextAlign.center,
              style: const TextStyle(color: AppPalette.muted)),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(onPressed: onRetry,
              icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ]));
      }
      return builder(snapshot.data as T);
    },
  );
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget? trailing;
  const SectionHeading({super.key, required this.title, this.caption, this.trailing});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (caption != null) ...[
        const SizedBox(height: 3),
        Text(caption!, style: const TextStyle(color: AppPalette.muted, fontSize: 12)),
      ],
    ])),
    if (trailing != null) trailing!,
  ]);
}

class SoftDivider extends StatelessWidget {
  const SoftDivider({super.key});
  @override
  Widget build(BuildContext context) => const Divider(color: AppPalette.border,
      height: 1, thickness: 1);
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message),
    backgroundColor: error ? AppPalette.danger : AppPalette.ink,
    behavior: SnackBarBehavior.floating));
}
