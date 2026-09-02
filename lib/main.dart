import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/apoio_provider.dart';
import 'screens/cronograma_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/historico_screen.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gbmlhxlfbpebgufatnyq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdibWxoeGxmYnBlYmd1ZmF0bnlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0MTA4NTAsImV4cCI6MjA4Nzk4Njg1MH0.oHA7qJz1Yuyhr5nhw1BR5FSdFXk40iamuvzi3b03S5Y',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ApoioProvider(),
      child: const ApoioCronoApp(),
    ),
  );
}

class ApoioCronoApp extends StatelessWidget {
  const ApoioCronoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cronograma Apoio Presencial',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    CronogramaScreen(),
    DashboardScreen(),
    HistoricoScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.calendar_view_week, label: 'Cronograma'),
    _NavItem(icon: Icons.bar_chart, label: 'Dashboard'),
    _NavItem(icon: Icons.history, label: 'Histórico'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Recarrega dados quando o app volta para primeiro plano
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ApoioProvider>().recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApoioProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo da escola no lugar do ícone de chapéu
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icons/logo_clodonil.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apoio Crono',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  'Clodonil Cardoso',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Indicador de conexão
          if (!provider.isOnline)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.danger,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Offline',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          // Badge da meta
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: provider.totalApoiosSemana(DateTime.now()) >= 15
                  ? AppTheme.accent
                  : AppTheme.warning,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.isLoading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else
                  Text(
                    '${provider.totalApoiosSemana(DateTime.now())}/15',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          // Loading overlay inicial (só aparece 1x ao abrir, por 5s no máximo)
          if (provider.isLoading && provider.apoios.isEmpty)
            Container(
              color: Colors.white.withValues(alpha: 0.92),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Carregando dados da nuvem...',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Sincronizando com o servidor',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          // Banner de reconexão (não bloqueia o app, fica no topo)
          if (!provider.isLoading && !provider.isOnline && provider.apoios.isEmpty)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                color: Colors.orange[700],
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.sync, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Reconectando ao servidor...',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => provider.recarregar(),
                      child: const Text('Tentar agora',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        height: 65,
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
