import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../injection_container.dart';
import '../../../nodes/domain/entities/node_entity.dart';
import '../../../nodes/presentation/widgets/nodes_style.dart';
import '../../domain/usecases/create_item.dart';
import '../bloc/add_item_bloc.dart';
import '../widgets/node_picker_sheet.dart';

const _maxImages = 5;

const _categories = [
  ('TOOLS', 'Tools'),
  ('BOOKS', 'Books'),
  ('ELECTRONICS', 'Electronics'),
  ('SPORTS', 'Sports'),
  ('OTHER', 'Other'),
];

const _conditions = [
  ('NEW', 'New'),
  ('GOOD', 'Good'),
  ('FAIR', 'Fair'),
  ('POOR', 'Poor'),
];

/// List an item: keep it with you (live immediately) or donate it to a Node
/// (waits in the manager's queue) — MASTER_PLAN §4.3 donation flow.
class AddItemPage extends StatelessWidget {
  const AddItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddItemBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('List an item')),
        body: BlocConsumer<AddItemBloc, AddItemState>(
          listener: (context, state) {
            if (state is AddItemFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) => switch (state) {
            AddItemSuccess() => _SuccessView(isDonation: state.isDonation),
            _ => _AddItemForm(
                submitting: state is AddItemSubmitting,
                serverErrors:
                    state is AddItemFailure ? state.fieldErrors : const {},
              ),
          },
        ),
      ),
    );
  }
}

class _AddItemForm extends StatefulWidget {
  const _AddItemForm({required this.submitting, required this.serverErrors});

  final bool submitting;
  final Map<String, List<String>> serverErrors;

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _rate = TextEditingController();
  final _deposit = TextEditingController();

  final List<XFile> _images = [];
  String? _category;
  String? _condition;
  bool _donate = false;
  NodeEntity? _node;
  String? _nodeError;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _rate.dispose();
    _deposit.dispose();
    super.dispose();
  }

  String? _serverError(String field) {
    final errors = widget.serverErrors[field];
    return (errors != null && errors.isNotEmpty) ? errors.first : null;
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 80,
      limit: _maxImages,
    );
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _images
        ..addAll(picked)
        ..removeRange(0, (_images.length - _maxImages).clamp(0, _images.length));
    });
  }

  Future<void> _pickNode() async {
    final node = await NodePickerSheet.show(context);
    if (node != null && mounted) {
      setState(() {
        _node = node;
        _nodeError = null;
      });
    }
  }

  String? _validateMoney(String? value) {
    final amount = double.tryParse((value ?? '').trim());
    if (amount == null || amount <= 0) return 'Enter an amount above 0';
    return null;
  }

  void _submit() {
    setState(() => _nodeError = null);
    final valid = _formKey.currentState!.validate();
    if (_donate && _node == null) {
      setState(() => _nodeError = 'Choose the Node to donate to.');
      return;
    }
    if (!valid) return;
    context.read<AddItemBloc>().add(AddItemSubmitted(CreateItemParams(
          title: _title.text.trim(),
          description: _description.text.trim(),
          category: _category!,
          condition: _condition!,
          dailyRate: _rate.text.trim(),
          depositAmount: _deposit.text.trim(),
          nodeId: _donate ? _node!.id : null,
          imagePaths: _images.map((image) => image.path).toList(),
        )));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _ImageRow(
            images: _images,
            onAdd: _images.length < _maxImages ? _pickImages : null,
            onRemove: (index) => setState(() => _images.removeAt(index)),
            error: _serverError('images'),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _title,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. DeWalt Power Drill',
              errorText: _serverError('title'),
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
              hintText: 'Condition details, accessories included…',
              errorText: _serverError('description'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    errorText: _serverError('category'),
                  ),
                  items: [
                    for (final (value, label) in _categories)
                      DropdownMenuItem(value: value, child: Text(label)),
                  ],
                  onChanged: (value) => setState(() => _category = value),
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _condition,
                  decoration: InputDecoration(
                    labelText: 'Condition',
                    errorText: _serverError('condition'),
                  ),
                  items: [
                    for (final (value, label) in _conditions)
                      DropdownMenuItem(value: value, child: Text(label)),
                  ],
                  onChanged: (value) => setState(() => _condition = value),
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _rate,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Daily rate',
                    prefixText: 'PKR ',
                    errorText: _serverError('daily_rate'),
                  ),
                  validator: _validateMoney,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _deposit,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Deposit',
                    prefixText: 'PKR ',
                    errorText: _serverError('deposit_amount'),
                  ),
                  validator: _validateMoney,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Where will it live?',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.home_outlined),
                label: Text('Keep with me'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.warehouse_outlined),
                label: Text('Donate to a Node'),
              ),
            ],
            selected: {_donate},
            onSelectionChanged: (selection) =>
                setState(() => _donate = selection.first),
          ),
          if (_donate) ...[
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: kNodeGold.withValues(alpha: 0.15),
                  child:
                      const Icon(Icons.warehouse_outlined, color: kNodeGold),
                ),
                title: Text(_node?.name ?? 'Choose a Node'),
                subtitle: _node != null
                    ? Text(
                        _node!.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const Text('Nearby Nodes, sorted by distance'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickNode,
              ),
            ),
            if (_nodeError != null || _serverError('node') != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _nodeError ?? _serverError('node')!,
                  style: TextStyle(color: scheme.error, fontSize: 12),
                ),
              ),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: widget.submitting ? null : _submit,
            icon: widget.submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              widget.submitting
                  ? 'Uploading…'
                  : _donate
                      ? 'Donate item'
                      : 'List item',
            ),
          ),
          if (widget.submitting)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Uploading photos — this can take a moment.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageRow extends StatelessWidget {
  const _ImageRow({
    required this.images,
    required this.onRemove,
    this.onAdd,
    this.error,
  });

  final List<XFile> images;
  final VoidCallback? onAdd;
  final void Function(int index) onRemove;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 92.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (up to $_maxImages)',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error!,
                style: TextStyle(color: scheme.error, fontSize: 12)),
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: size,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < images.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(images[i].path),
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
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.isDonation});

  final bool isDonation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, title, message) = isDonation
        ? (
            Icons.hourglass_top_rounded,
            kNodeGold,
            'Donation on its way',
            'Waiting for the Node Manager to accept your donation. You can '
                'track it under "My items".',
          )
        : (
            Icons.check_circle_outline,
            scheme.primary,
            'Your item is live',
            'Neighbours within 5 km can now find and rent it.',
          );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () {
                context.pop();
                context.push('/items/my');
              },
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('My items'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back to the map'),
            ),
          ],
        ),
      ),
    );
  }
}
