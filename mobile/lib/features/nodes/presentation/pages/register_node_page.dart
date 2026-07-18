import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/location_service.dart';
import '../../../../injection_container.dart';
import '../bloc/register_node_bloc.dart';
import '../widgets/nodes_style.dart';

const _maxPhotos = 3;

const _days = [
  ('mon', 'Monday'),
  ('tue', 'Tuesday'),
  ('wed', 'Wednesday'),
  ('thu', 'Thursday'),
  ('fri', 'Friday'),
  ('sat', 'Saturday'),
  ('sun', 'Sunday'),
];

/// "Become a Node Manager" — registers a community storeroom via
/// POST /nodes/ (multipart). On success the backend flips the user's role
/// to NODE_MANAGER and the node awaits admin approval.
class RegisterNodePage extends StatelessWidget {
  const RegisterNodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RegisterNodeBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Register a Node')),
        body: BlocConsumer<RegisterNodeBloc, RegisterNodeState>(
          listener: (context, state) {
            if (state is RegisterNodeFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) => switch (state) {
            RegisterNodeSuccess() => const _SuccessView(),
            _ => _RegisterForm(
                submitting: state is RegisterNodeSubmitting,
                serverErrors:
                    state is RegisterNodeFailure ? state.fieldErrors : const {},
              ),
          },
        ),
      ),
    );
  }
}

/// Per-day editor state: closed toggle + a time range.
class _DayHours {
  _DayHours({this.closed = false});

  bool closed;
  TimeOfDay open = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay close = const TimeOfDay(hour: 18, minute: 0);

  /// Backend wire format: "HH:MM-HH:MM" or "closed" (§4.2).
  String toWire() => closed
      ? 'closed'
      : '${_fmt(open)}-${_fmt(close)}';

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({required this.submitting, required this.serverErrors});

  final bool submitting;
  final Map<String, List<String>> serverErrors;

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _capacity = TextEditingController();

  final Map<String, _DayHours> _hours = {
    for (final day in _days) day.$1: _DayHours(closed: day.$1 == 'sun'),
  };

  final List<XFile> _photos = [];
  double? _lat;
  double? _lng;
  bool _locating = false;
  String? _coordsError;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _capacity.dispose();
    super.dispose();
  }

  String? _serverError(String field) {
    final errors = widget.serverErrors[field];
    return (errors != null && errors.isNotEmpty) ? errors.first : null;
  }

  /// GPS -> reverse geocode -> fill address + capture exact coordinates.
  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _coordsError = null;
    });
    final location = sl<LocationService>();
    try {
      if (await location.ensurePermission() != LocationStatus.granted) {
        throw Exception('permission');
      }
      final position = await location.getCurrentPosition();
      _lat = position.latitude;
      _lng = position.longitude;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [p.street, p.subLocality, p.locality]
              .where((part) => part != null && part.trim().isNotEmpty)
              .toList();
          if (parts.isNotEmpty) _address.text = parts.join(', ');
        }
      } catch (_) {
        // Coordinates captured; the user can still type the address.
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _coordsError =
            'Couldn\'t get your location — check the permission and GPS.');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 80,
      limit: _maxPhotos,
    );
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _photos
        ..addAll(picked)
        ..removeRange(0, (_photos.length - _maxPhotos).clamp(0, _photos.length));
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // No "use my location" tap? Try to geocode the typed address instead.
    if (_lat == null || _lng == null) {
      try {
        final locations = await locationFromAddress(_address.text.trim());
        _lat = locations.first.latitude;
        _lng = locations.first.longitude;
      } catch (_) {
        setState(() => _coordsError =
            'Couldn\'t locate this address — tap "Use my current location".');
        return;
      }
    }
    if (!mounted) return;
    context.read<RegisterNodeBloc>().add(RegisterNodeSubmitted(
          name: _name.text.trim(),
          description: _description.text.trim(),
          address: _address.text.trim(),
          lat: _lat!,
          lng: _lng!,
          capacity: int.parse(_capacity.text.trim()),
          operatingHours:
              _hours.map((day, hours) => MapEntry(day, hours.toWire())),
          photoPaths: _photos.map((photo) => photo.path).toList(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hoursError = _serverError('operating_hours');
    final photosError = _serverError('photos');
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Run a community storeroom your neighbours can borrow from. '
            'An admin reviews every new Node before it appears on the map.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Node name',
              hintText: 'e.g. Block C Storeroom',
              errorText: _serverError('name'),
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'What is this space, and what can people expect?',
              errorText: _serverError('description'),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _address,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Address',
              hintText: 'Street, area',
              errorText: _serverError('address') ?? _coordsError,
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Required' : null,
            onChanged: (_) {
              // Typed address replaces previously captured coordinates.
              if (_coordsError != null) setState(() => _coordsError = null);
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _lat != null ? Icons.check_circle : Icons.my_location,
                      size: 18,
                    ),
              label: Text(_lat != null
                  ? 'Location captured'
                  : 'Use my current location'),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _capacity,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Capacity',
              hintText: 'Max number of items the room holds',
              errorText: _serverError('capacity'),
            ),
            validator: (value) {
              final n = int.tryParse((value ?? '').trim());
              if (n == null || n <= 0) return 'Enter a number above 0';
              return null;
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Operating hours',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (hoursError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(hoursError,
                  style: TextStyle(color: scheme.error, fontSize: 12)),
            ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final day in _days)
                    _DayHoursRow(
                      label: day.$2,
                      hours: _hours[day.$1]!,
                      onChanged: () => setState(() {}),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Photos (up to $_maxPhotos)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (photosError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(photosError,
                  style: TextStyle(color: scheme.error, fontSize: 12)),
            ),
          const SizedBox(height: 8),
          _PhotoRow(
            photos: _photos,
            onAdd: _photos.length < _maxPhotos ? _pickPhotos : null,
            onRemove: (index) => setState(() => _photos.removeAt(index)),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: widget.submitting ? null : _submit,
            icon: widget.submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.warehouse_outlined),
            label: Text(
                widget.submitting ? 'Registering…' : 'Register my Node'),
          ),
        ],
      ),
    );
  }
}

class _DayHoursRow extends StatelessWidget {
  const _DayHoursRow({
    required this.label,
    required this.hours,
    required this.onChanged,
  });

  final String label;
  final _DayHours hours;
  final VoidCallback onChanged;

  Future<void> _pickTime(BuildContext context, {required bool isOpen}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? hours.open : hours.close,
    );
    if (picked == null) return;
    if (isOpen) {
      hours.open = picked;
    } else {
      hours.close = picked;
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(label)),
          Expanded(
            child: hours.closed
                ? Text('Closed',
                    style: TextStyle(color: scheme.onSurfaceVariant))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TimeButton(
                        time: hours.open,
                        onTap: () => _pickTime(context, isOpen: true),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('–'),
                      ),
                      _TimeButton(
                        time: hours.close,
                        onTap: () => _pickTime(context, isOpen: false),
                      ),
                    ],
                  ),
          ),
          Switch(
            value: !hours.closed,
            onChanged: (open) {
              hours.closed = !open;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.time, required this.onTap});

  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(_DayHours._fmt(time),
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.photos,
    required this.onRemove,
    this.onAdd,
  });

  final List<XFile> photos;
  final VoidCallback? onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 92.0;
    return SizedBox(
      height: size,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < photos.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(photos[i].path),
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => onRemove(i),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (onAdd != null)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.add_a_photo_outlined,
                    color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kNodeGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  size: 48, color: kNodeGold),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Node is pending approval',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'An admin will review it shortly. Once approved, it appears as '
              'a gold marker on everyone\'s map — and you\'re now a Node '
              'Manager: find "My Node" in the menu.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Back to the map'),
            ),
          ],
        ),
      ),
    );
  }
}
