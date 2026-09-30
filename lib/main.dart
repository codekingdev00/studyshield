import 'package:flutter/material.dart';

import 'focus_session_screen.dart';
import 'models/study_material.dart';
import 'study_api.dart';

void main() {
  runApp(const StudyShieldApp());
}

class StudyShieldApp extends StatelessWidget {
  const StudyShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyShield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF101418),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<StudyGroup>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = StudyApi.fetchGroups();
  }

  Future<void> _refresh() async {
    final future = StudyApi.fetchGroups();
    setState(() => _groupsFuture = future);
    await future;
  }

  void _openMaterial(StudyMaterial material) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusSessionScreen(material: material),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 4),
              child: Row(
                children: [
                  Icon(Icons.center_focus_strong,
                      size: 32, color: Colors.tealAccent),
                  SizedBox(width: 10),
                  Text(
                    'StudyShield',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Pick a subject to start reading. Your screen locks the '
                'moment you start, and unlocks the moment you stop.',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<StudyGroup>>(
                  future: _groupsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final groups = snapshot.data ?? const [];
                    if (groups.isEmpty) {
                      return ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No study materials available yet.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        for (final group in groups) ...[
                          Row(
                            children: [
                              const Icon(Icons.groups,
                                  size: 18, color: Colors.white38),
                              const SizedBox(width: 6),
                              Text(
                                group.name,
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final material in group.materials) ...[
                            _MaterialCard(
                              material: material,
                              onTap: () => _openMaterial(material),
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.material, required this.onTap});

  final StudyMaterial material;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1B2127),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withValues(alpha: 0.2),
          child: Icon(material.icon, color: Colors.tealAccent),
        ),
        title: Text(
          material.title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  material.summary,
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
              if (material.hasVideo)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.play_circle_fill,
                      color: Colors.redAccent, size: 16),
                ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              material.subject,
              style: const TextStyle(color: Colors.tealAccent, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '~${material.suggestedMinutes} min',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
