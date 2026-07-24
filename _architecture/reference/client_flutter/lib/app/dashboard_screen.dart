import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_renderer.dart';
import 'package:client_flutter/sdui/core/sdui_transport.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<SduiNode>? _nodes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/mock_sdui/dashboard.json',
      );
      final nodes = SduiTransport.decodeJson(jsonStr);

      if (mounted) {
        setState(() {
          _nodes = nodes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('horAIzon Dashboard'),
          centerTitle: true,
        ),
        body: Center(child: Text('Failed to load dashboard: $_error')),
      );
    }

    final nodes = _nodes;
    if (nodes == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('horAIzon Dashboard'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final dispatcher = ref.watch(sduiDispatcherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('horAIzon Dashboard'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: nodes.map((node) {
            return SliverToBoxAdapter(
              child: SduiRenderer(node: node, dispatcher: dispatcher),
            );
          }).toList(),
        ),
      ),
    );
  }
}
