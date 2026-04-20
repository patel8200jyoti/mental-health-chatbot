import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'admin_users.dart';
import 'admin_doctors.dart';
import 'admin_mood_journal.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  static const _tabs = [
    AdminDashboard(),
    AdminUsersPage(),
    AdminDoctorsPage(),
    AdminMoodJournalPage(),
  ];

  static const _items = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Users'),
    BottomNavigationBarItem(icon: Icon(Icons.verified_user_outlined), activeIcon: Icon(Icons.verified_user), label: 'Doctors'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _tab, children: _tabs),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) => setState(() => _tab = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 12,
      items: _items,
    ),
  );
}