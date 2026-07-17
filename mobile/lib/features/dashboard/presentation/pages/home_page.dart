import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Placeholder dashboard: greets the signed-in user; real content (nearby
/// nodes + items) lands in a later phase.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neighbor Node'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
          ),
        ],
      ),
      body: Center(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state is Authenticated ? state.user : null;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.person_outline,
                      size: 36, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: 16),
                Text(
                  user != null ? 'Hi, ${user.displayName}!' : 'Welcome!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (user != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Your neighbourhood dashboard is coming soon',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
