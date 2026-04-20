import 'package:flutter/material.dart';
import 'proff_dash.dart';
import 'proff_patients.dart';
import 'proff_crisis.dart';
import 'proff_analytics.dart';

class ProfessionalShell extends StatefulWidget {
  const ProfessionalShell({super.key});
  @override
  State<ProfessionalShell> createState() => _ProfessionalShellState();
}

class _ProfessionalShellState extends State<ProfessionalShell> {
  int _tab = 0;

  // NOT const — these widgets have state and cannot be const
  final List<Widget> _tabs = const [
    ProfDashboard(),
    ProfPatientsPage(),
    ProfCrisisPage(),
    ProfAnalyticsPage(),
  ];

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people_outline),
      activeIcon: Icon(Icons.people),
      label: 'Patients',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.warning_amber_outlined),
      activeIcon: Icon(Icons.warning_amber_rounded),
      label: 'Crisis',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart_outlined),
      activeIcon: Icon(Icons.bar_chart),
      label: 'Analytics',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _tab, children: _tabs),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 12,
          items: _items,
        ),
      );
}