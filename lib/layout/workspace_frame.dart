import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';

/// Navegación persistente entre módulos. Cada módulo cambia SOLO el área central.
class WorkspaceItem {
  final String id, title, section;
  final IconData icon;
  const WorkspaceItem(this.id, this.title, this.icon, this.section);
}

class WorkspaceFrame extends StatefulWidget {
  final String selected;
  final List<WorkspaceItem> items;
  final ValueChanged<String> onSelect;
  final String title, subtitle, userName, userRole;
  final VoidCallback onLogout;
  final Widget child;
  final bool isClient;
  final VoidCallback? onPrimary, onSearch;
  final String primaryText;
  const WorkspaceFrame({super.key, required this.selected, required this.items,
    required this.onSelect, required this.title, required this.subtitle,
    required this.userName, required this.userRole, required this.onLogout,
    required this.child, this.isClient = false,
    this.onPrimary, this.onSearch, this.primaryText = 'Nuevo'});
  @override
  State<WorkspaceFrame> createState() => _WorkspaceFrameState();
}

class _WorkspaceFrameState extends State<WorkspaceFrame> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 1020;
    final sidebar = _WorkspaceSidebar(items: widget.items,
      selected: widget.selected, userName: widget.userName,
      userRole: widget.userRole, onLogout: widget.onLogout,
      isClient: widget.isClient,
      onSelect: (value) {
        if (!desktop) scaffoldKey.currentState?.closeDrawer();
        widget.onSelect(value);
      });
    return Scaffold(
      key: scaffoldKey,
      drawer: desktop ? null : Drawer(width: 276, backgroundColor: AppPalette.navy,
        child: sidebar),
      body: SafeArea(child: Row(children: [
        if (desktop) SizedBox(width: 266, child: sidebar),
        Expanded(child: Column(children: [
          _WorkspaceTopbar(
            title: widget.title, subtitle: widget.subtitle,
            userName: widget.userName, userRole: widget.userRole,
            onLogout: widget.onLogout, onSearch: widget.onSearch,
            onPrimary: widget.onPrimary, primaryText: widget.primaryText,
            showMenu: !desktop,
            onMenu: () => scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(child: DecoratedBox(
            decoration: const BoxDecoration(color: AppPalette.background),
            child: widget.child,
          )),
        ])),
      ])),
    );
  }
}

class _WorkspaceSidebar extends StatelessWidget {
  final List<WorkspaceItem> items;
  final String selected, userName, userRole;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;
  final bool isClient;
  const _WorkspaceSidebar({required this.items, required this.selected,
    required this.userName, required this.userRole,
    required this.onSelect, required this.onLogout, required this.isClient});

  @override
  Widget build(BuildContext context) {
    final sections = <String, List<WorkspaceItem>>{};
    for (final item in items) {
      sections.putIfAbsent(item.section, () => []).add(item);
    }
    return ColoredBox(color: AppPalette.navy, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(19, 23, 12, 16),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/brand/obratek_marca_oscura.png', width: 43,
              height: 43, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.architecture,
                color: AppPalette.cyan, size: 37))),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Obratek', style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.9)),
              Text(isClient ? 'PORTAL DE CLIENTES' : 'PLATAFORMA OPERATIVA',
                style: const TextStyle(color: Color(0xFF92A6C5),
                  fontWeight: FontWeight.w600, letterSpacing: 0.6, fontSize: 9)),
            ])),
          const Padding(padding: EdgeInsets.only(right: 7), child: Text('0.0.004',
            style: TextStyle(color: Colors.white70, fontSize: 12))),
        ])),
      if (AppConfig.demoMode) Container(
        margin: const EdgeInsets.fromLTRB(19, 0, 19, 9),
        alignment: Alignment.centerLeft,
        child: const Text('●  MODO DEMOSTRACIÓN', style: TextStyle(
          color: AppPalette.cyan, fontSize: 10, letterSpacing: 0.6))),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(11, 12, 11, 6),
        children: [
          for (final entry in sections.entries) ...[
            Padding(padding: const EdgeInsets.fromLTRB(13, 11, 13, 7),
              child: Text(entry.key.toUpperCase(),
                style: const TextStyle(color: Color(0xFF8DA2C2),
                  letterSpacing: 1.25, fontSize: 10, fontWeight: FontWeight.w700))),
            for (final item in entry.value)
              _SidebarEntry(item: item, selected: selected == item.id,
                onTap: () => onSelect(item.id)),
            const SizedBox(height: 10),
          ]
        ])),
      Container(
        padding: const EdgeInsets.fromLTRB(13, 14, 10, 15),
        decoration: const BoxDecoration(border: Border(top: BorderSide(
          color: Color(0xFF2B3B57)))),
        child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: const Color(0xFF334969),
            child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 12)),
            Text(userRole, style: const TextStyle(color: Color(0xFF9EB0CD), fontSize: 11)),
          ])),
          IconButton(onPressed: onLogout, tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20)),
        ]),
      ),
    ]));
  }
}

class _SidebarEntry extends StatelessWidget {
  final WorkspaceItem item;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarEntry({required this.item, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Material(color: selected ? AppPalette.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(children: [
            Icon(item.icon, size: 19, color: selected ? Colors.white : const Color(0xFFE0E9F6)),
            const SizedBox(width: 12),
            Expanded(child: Text(item.title, style: TextStyle(fontSize: 12.5,
              color: selected ? Colors.white : const Color(0xFFE0E9F6),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500))),
          ])),
      ),
    ),
  );
}

class _WorkspaceTopbar extends StatelessWidget {
  final String title, subtitle, userName, userRole, primaryText;
  final VoidCallback onLogout, onMenu;
  final VoidCallback? onPrimary, onSearch;
  final bool showMenu;
  const _WorkspaceTopbar({required this.title, required this.subtitle,
    required this.userName, required this.userRole, required this.onLogout,
    required this.onMenu, required this.showMenu,
    required this.onPrimary, required this.onSearch, required this.primaryText});
  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    decoration: const BoxDecoration(color: Colors.white,
      border: Border(bottom: BorderSide(color: AppPalette.border))),
    child: Row(children: [
      if (showMenu) ...[
        IconButton(icon: const Icon(Icons.menu_rounded), tooltip: 'Abrir menú',
          onPressed: onMenu),
        const SizedBox(width: 7),
      ],
      Container(padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: AppPalette.navy,
          borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.space_dashboard_outlined, color: Colors.white, size: 19)),
      const SizedBox(width: 12),
      Flexible(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 19, color: AppPalette.ink,
              fontWeight: FontWeight.w800)),
          Text('Obratek 0.0.004  ›  $subtitle', overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppPalette.muted, fontSize: 11)),
        ])),
      const Spacer(),
      if (onSearch != null && MediaQuery.sizeOf(context).width >= 1000)
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 315),
          child: OutlinedButton.icon(onPressed: onSearch,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Buscar en Obratek...', maxLines: 1,
              overflow: TextOverflow.ellipsis))),
      if (onPrimary != null) ...[
        const SizedBox(width: 11),
        FilledButton.icon(onPressed: onPrimary,
          icon: const Icon(Icons.add_rounded, size: 18), label: Text(primaryText)),
      ],
      const SizedBox(width: 10),
      PopupMenuButton<String>(tooltip: 'Mi cuenta',
        onSelected: (v) { if (v == 'logout') onLogout(); },
        itemBuilder: (_) => [
          PopupMenuItem(enabled: false, child: Text(userName)),
          PopupMenuItem(enabled: false, child: Text(userRole)),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
        ],
        child: CircleAvatar(backgroundColor: AppPalette.navy,
          child: Text(userName.isEmpty ? 'U' : userName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800))),
      ),
    ]),
  );
}
