import 'package:flutter/material.dart';

/// Phase-4 placeholder behind "Request to Rent" — the QR digital-handshake
/// rental flow (MASTER_PLAN §4.4) lands next phase.
class TransactionsStubPage extends StatelessWidget {
  const TransactionsStubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Request to Rent')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.qr_code_2,
                    size: 48, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 24),
              Text(
                'Transactions coming next phase',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Rental requests, the QR pickup/return handshake, and '
                'deposits arrive in Phase 4.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
