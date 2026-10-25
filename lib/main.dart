import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF008A09)),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF171717), fontSize: 18),
        ),
      ),
      home: const LiveOutputPage(),
    );
  }
}

enum ConnectionStatus {
  connected('Connected', Color(0xFF008A09)),
  connecting('Connecting', Color(0xFFBE8500)),
  offline('Offline', Color(0xFFCA3939));

  const ConnectionStatus(this.label, this.color);
  final String label;
  final Color color;
}

enum DemoState {
  connected('All connected'),
  connecting('Hardware connecting'),
  hardwareOffline('Hardware offline'),
  modelOffline('Model offline');

  const DemoState(this.label);
  final String label;
}

class LiveOutputPage extends StatefulWidget {
  const LiveOutputPage({super.key});

  @override
  State<LiveOutputPage> createState() => _LiveOutputPageState();
}

class _LiveOutputPageState extends State<LiveOutputPage> {
  DemoState _demoState = DemoState.connected;
  final List<String> _messages = [];
  final ScrollController _outputScroll = ScrollController();
  late final StreamSubscription<String> _subscription;

  ConnectionStatus get _hardwareStatus => switch (_demoState) {
    DemoState.connecting => ConnectionStatus.connecting,
    DemoState.hardwareOffline => ConnectionStatus.offline,
    _ => ConnectionStatus.connected,
  };

  ConnectionStatus get _modelStatus => _demoState == DemoState.modelOffline
      ? ConnectionStatus.offline
      : ConnectionStatus.connected;

  String get _readiness => switch (_demoState) {
    DemoState.connected => 'Ready',
    DemoState.connecting => 'Connecting…',
    _ => 'Waiting for connection',
  };

  @override
  void initState() {
    super.initState();
    // Replace this demo source with the hardware/model stream when available.
    _subscription = TestStreamSource().messages.listen((message) {
      if (!mounted) return;
      setState(() => _messages.add(message));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_outputScroll.hasClients) return;
        _outputScroll.animateTo(
          _outputScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _outputScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 600;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 24 : 12,
                vertical: wide ? 24 : 12,
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 440),
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD8D8D8)),
                        borderRadius: BorderRadius.circular(wide ? 40 : 28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live output',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          StatusPill(
                            label: 'Hardware',
                            status: _hardwareStatus,
                          ),
                          const SizedBox(height: 12),
                          StatusPill(label: 'Model', status: _modelStatus),
                          const SizedBox(height: 24),
                          Container(
                            height: (constraints.maxHeight - 330).clamp(
                              280.0,
                              520.0,
                            ),
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCFCFB),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE3E3E3),
                              ),
                            ),
                            child: SingleChildScrollView(
                              controller: _outputScroll,
                              child: SelectableText(
                                _messages.isEmpty
                                    ? 'Text from your hardware and model appears here. New lines stream in as they arrive.'
                                    : _messages.join('\n\n'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  height: 1.65,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: Text(_readiness)),
                              const Text('Read-only'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Demo connection states',
                    style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: DemoState.values.map((state) {
                      return OutlinedButton(
                        onPressed: () => setState(() => _demoState = state),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF252525),
                          backgroundColor: _demoState == state
                              ? const Color(0xFFEFF6EF)
                              : Colors.white,
                          side: BorderSide(
                            color: _demoState == state
                                ? const Color(0xFF87A889)
                                : const Color(0xFFD5D5D5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(state.label),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.status});

  final String label;
  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          Text(label),
          Text(status.label, style: const TextStyle(color: Color(0xFF606060))),
        ],
      ),
    );
  }
}

class TestStreamSource {
  Stream<String> get messages async* {
    const messages = [
      'test test test',
      'table ahead',
      'beep boop',
      'Anna is standing 10 feet ahead facing you',
      'Halt!',
    ];
    for (final message in messages) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      yield message;
    }
  }
}
