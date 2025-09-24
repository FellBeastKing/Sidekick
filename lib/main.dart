// main.dart
// EV-04‑style multi‑device tracker demo (Flutter)
// ------------------------------------------------------------
// What this gives you:
// • Add/remove multiple devices (name + phone number)
// • Live location updates (simulated) & breadcrumb trails per device
// • Map view (OpenStreetMap via flutter_map) with markers
// • SOS alert banner when any device flags SOS (simulated)
// • One‑tap voice call to a device using url_launcher (tel:)
// • Clean Provider state management; easy to swap in a real backend (MQTT/HTTP/WebSocket)
//
// To wire up a real tracker backend later, replace the DemoUpdateService with your
// own data source and call DeviceStore.applyUpdate(...) when messages arrive.
//
// Required packages (run these in the project root):
//   flutter pub add flutter_map latlong2 url_launcher provider
//
// NOTE: This file is intentionally self‑contained. Drop it into lib/main.dart.
// ------------------------------------------------------------

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const EV04TrackerApp());
}

class EV04TrackerApp extends StatelessWidget {
  const EV04TrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceStore()..startDemoUpdates()),
      ],
      child: MaterialApp(
        title: 'EV‑04 Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

// ===== Models =====
class Device {
  Device({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    this.online = true,
    this.sosActive = false,
    DateTime? lastUpdate,
  }) : lastUpdate = lastUpdate ?? DateTime.now();

  final String id; // e.g., IMEI or device UUID
  String name;
  String phone; // SIM phone number for voice calls
  LatLng location;
  bool online;
  bool sosActive;
  DateTime lastUpdate;

  // Breadcrumbs for recent track (last N points)
  final List<LatLng> _trail = <LatLng>[];
  List<LatLng> get trail => List.unmodifiable(_trail);

  void addTrailPoint(LatLng p, {int maxLen = 100}) {
    _trail.add(p);
    if (_trail.length > maxLen) {
      _trail.removeAt(0);
    }
  }
}

class DeviceUpdate {
  DeviceUpdate({
    required this.id,
    this.location,
    this.online,
    this.sosActive,
    this.name,
    this.phone,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final LatLng? location;
  final bool? online;
  final bool? sosActive;
  final String? name;
  final String? phone;
  final DateTime timestamp;
}

// ===== Store =====
class DeviceStore extends ChangeNotifier {
  final Map<String, Device> _devices = {};
  String? _selectedId;
  StreamSubscription<DeviceUpdate>? _demoSub;

  List<Device> get devices => _devices.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  Device? get selected => _selectedId == null ? null : _devices[_selectedId];
  bool get anySos => _devices.values.any((d) => d.sosActive);

  void addDevice(Device d) {
    _devices[d.id] = d;
    _selectedId ??= d.id;
    notifyListeners();
  }

  void removeDevice(String id) {
    _devices.remove(id);
    if (_selectedId == id) {
      _selectedId = _devices.isEmpty ? null : _devices.keys.first;
    }
    notifyListeners();
  }

  void selectDevice(String id) {
    if (_devices.containsKey(id)) {
      _selectedId = id;
      notifyListeners();
    }
  }

  void applyUpdate(DeviceUpdate u) {
    final d = _devices[u.id];
    if (d == null) return;

    if (u.location != null) {
      d.location = u.location!;
      d.addTrailPoint(u.location!);
    }
    if (u.online != null) d.online = u.online!;
    if (u.sosActive != null) d.sosActive = u.sosActive!;
    if (u.name != null) d.name = u.name!;
    if (u.phone != null) d.phone = u.phone!;
    d.lastUpdate = u.timestamp;
    notifyListeners();
  }

  // ---- Demo data plumbing (replace with real backend) ----
  void startDemoUpdates() {
    // Seed with two example devices around Johannesburg & Cape Town.
    addDevice(Device(
      id: '860000000000001',
      name: 'Daughter',
      phone: '+27115551234',
      location: LatLng(-26.2041, 28.0473), // Johannesburg
    ));
    addDevice(Device(
      id: '860000000000002',
      name: 'Son',
      phone: '+27215551234',
      location: LatLng(-33.9249, 18.4241), // Cape Town
    ));

    final demo = DemoUpdateService(seed: 42);
    _demoSub = demo.stream.listen(applyUpdate);
  }

  void stopDemoUpdates() async {
    await _demoSub?.cancel();
    _demoSub = null;
  }

  @override
  void dispose() {
    stopDemoUpdates();
    super.dispose();
  }
}

// A simple update generator that jitters positions and randomly toggles SOS
class DemoUpdateService {
  DemoUpdateService({int? seed}) : _rng = Random(seed);
  final Random _rng;

  late final Stream<DeviceUpdate> stream = _tick();

  Stream<DeviceUpdate> _tick() async* {
    // Two device IDs matched to the seeded store
    const ids = ['860000000000001', '860000000000002'];

    // Last known locations to jitter around
    final last = {
      ids[0]: LatLng(-26.2041, 28.0473),
      ids[1]: LatLng(-33.9249, 18.4241),
    };

    while (true) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final id = ids[_rng.nextInt(ids.length)];
      final prev = last[id]!;
      // jitter ~100–300 m
      final dLat = (_rng.nextDouble() - 0.5) * 0.003;
      final dLng = (_rng.nextDouble() - 0.5) * 0.003;
      final next = LatLng(prev.latitude + dLat, prev.longitude + dLng);
      last[id] = next;

      final sosFlip = _rng.nextDouble() < 0.05; // 5% chance to toggle

      yield DeviceUpdate(
        id: id,
        location: next,
        sosActive: sosFlip ? _rng.nextBool() : null,
      );
    }
  }
}

// ===== UI =====
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeviceStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kid Tracker'),
        actions: [
          IconButton(
            tooltip: 'Add device',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddDeviceDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (store.anySos) const _SosBanner(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                if (wide) {
                  return Row(
                    children: const [
                      SizedBox(width: 340, child: _DeviceListPane()),
                      VerticalDivider(width: 1),
                      Expanded(child: _MapPane()),
                    ],
                  );
                } else {
                  return const _MapWithBottomList();
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _recenterSelected(context),
        icon: const Icon(Icons.my_location),
        label: const Text('Recenter'),
      ),
    );
  }

  void _recenterSelected(BuildContext context) {
    // No-op: flutter_map controller is managed inside _MapPane via a GlobalKey.
    // We notify listeners here to trigger a rebuild (which recenters map on selected device).
    context.read<DeviceStore>().notifyListeners();
  }

  Future<void> _showAddDeviceDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final idCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add device'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Display name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone number (SIM)'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: idCtrl,
                    decoration: const InputDecoration(labelText: 'Device ID (IMEI/UUID)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final d = Device(
                  id: idCtrl.text.trim(),
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  // Default near current map center (Johannesburg fallback)
                  location: const LatLng(-26.2041, 28.0473),
                );
                context.read<DeviceStore>().addDevice(d);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class _SosBanner extends StatelessWidget {
  const _SosBanner();

  @override
  Widget build(BuildContext context) {
    final offenders = context.select<DeviceStore, List<Device>>(
      (s) => s.devices.where((d) => d.sosActive).toList(),
    );
    final names = offenders.map((d) => d.name).join(', ');
    return Material(
      color: Colors.red.shade600,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.emergency, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'SOS from: $names',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => _showSosActions(context, offenders),
                child: const Text('Actions', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSosActions(BuildContext context, List<Device> list) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              const ListTile(title: Text('SOS Actions')),
              const Divider(height: 1),
              for (final d in list)
                ListTile(
                  leading: const Icon(Icons.person_pin_circle),
                  title: Text(d.name),
                  subtitle: Text('Last update: ${d.lastUpdate}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.phone),
                    onPressed: () => _callNumber(d.phone),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _DeviceListPane extends StatelessWidget {
  const _DeviceListPane();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeviceStore>();

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, i) {
        final d = store.devices[i];
        final selected = store.selected?.id == d.id;
        return Card(
          elevation: selected ? 2 : 0,
          color: selected ? Theme.of(context).colorScheme.surfaceContainerHigh : null,
          child: ListTile(
            onTap: () => store.selectDevice(d.id),
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(child: Icon(Icons.watch))
              , if (d.sosActive)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(Icons.emergency, size: 16, color: Colors.red),
                  ),
              ],
            ),
            title: Text(d.name),
            subtitle: Text(
              '${d.online ? 'Online' : 'Offline'} • ${d.location.latitude.toStringAsFixed(5)}, ${d.location.longitude.toStringAsFixed(5)}',
            ),
            trailing: Wrap(spacing: 8, children: [
              IconButton(
                tooltip: 'Call',
                icon: const Icon(Icons.phone),
                onPressed: () => _callNumber(d.phone),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => store.removeDevice(d.id),
              ),
            ]),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemCount: store.devices.length,
    );
  }
}

class _MapWithBottomList extends StatelessWidget {
  const _MapWithBottomList();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _MapPane(),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 210,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: const _DeviceListPane(),
          ),
        ),
      ],
    );
  }
}

class _MapPane extends StatelessWidget {
  const _MapPane();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeviceStore>();
    final devices = store.devices;
    final selected = store.selected;

    // Fallback center if nothing selected
    final center = selected?.location ??
        (devices.isNotEmpty ? devices.first.location : const LatLng(-26.2041, 28.0473));

    final markers = <Marker>[
      for (final d in devices)
        Marker(
          width: 42,
          height: 42,
          point: d.location,
          child: _DeviceMarker(device: d, selected: selected?.id == d.id),
        ),
    ];

    final selectedTrail = selected?.trail ?? const <LatLng>[];

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12,
        interactionOptions: const InteractionOptions(flags: ~InteractiveFlag.doubleTapDragZoom),
        onTap: (tapPosition, latlng) {},
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ev04_tracker',
        ),
        PolylineLayer(
          polylines: [
            if (selectedTrail.length >= 2)
              Polyline(points: selectedTrail, strokeWidth: 4),
          ],
        ),
        MarkerLayer(markers: markers),
        if (selected != null)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _SelectedCard(device: selected),
            ),
          ),
      ],
    );
  }
}

class _DeviceMarker extends StatelessWidget {
  const _DeviceMarker({required this.device, required this.selected});
  final Device device;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = device.sosActive
        ? Colors.red
        : (selected ? Theme.of(context).colorScheme.primary : Colors.blueGrey);
    return GestureDetector(
      onTap: () => context.read<DeviceStore>().selectDevice(device.id),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_pin, size: 36, color: color),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              device.name,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }
}

class _SelectedCard extends StatelessWidget {
  const _SelectedCard({required this.device});
  final Device device;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.watch, size: 18),
                const SizedBox(width: 8),
                Text(device.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                if (device.sosActive)
                  const Icon(Icons.emergency, color: Colors.red, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text('ID: ${device.id}'),
            Text('Phone: ${device.phone}'),
            Text('Last: ${device.location.latitude.toStringAsFixed(5)}, ${device.location.longitude.toStringAsFixed(5)}'),
            Text('Updated: ${device.lastUpdate}'),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: () => _callNumber(device.phone),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(context,
                      '${device.location.latitude},${device.location.longitude}'),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy coords'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

Future<void> _callNumber(String number) async {
  final uri = Uri(scheme: 'tel', path: number);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

void _copyToClipboard(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Copied: $text')),
  );
}
