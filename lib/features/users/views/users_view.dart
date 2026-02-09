import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../data/models/user_profile_model.dart';
import '../../../themes/app_theme.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';
import '../widgets/user_form_dialog.dart';

/// Users management screen (admin-only).
///
/// Displays a searchable table of users with add/edit actions.
class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UsersBloc>(
      create: (_) => GetIt.instance<UsersBloc>()..add(const LoadUsersEvent()),
      child: const _UsersBody(),
    );
  }
}

class _UsersBody extends StatefulWidget {
  const _UsersBody();

  @override
  State<_UsersBody> createState() => _UsersBodyState();
}

class _UsersBodyState extends State<_UsersBody> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<UsersBloc>().add(SearchUsersEvent(query));
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const UserFormDialog(),
    );
    if (result != null && mounted) {
      context.read<UsersBloc>().add(CreateUserEvent(result));
    }
  }

  Future<void> _showEditDialog(UserProfileModel user) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => UserFormDialog(user: user),
    );
    if (result != null && mounted) {
      context.read<UsersBloc>().add(UpdateUserEvent(user.id, result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UsersBloc, UsersState>(
      listener: (context, state) {
        if (state is UserSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        if (state is UserSaveError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: TmzColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: TmzAppBar(
          app: WatchAppIdentity.streamWatch,
          customTitle: 'Users',
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TmzColors.gray90,
                border: Border(
                  bottom: BorderSide(color: TmzColors.gray70, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TmzColors.tmzRed,
                      foregroundColor: TmzColors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Users table
            Expanded(
              child: BlocBuilder<UsersBloc, UsersState>(
                builder: (context, state) {
                  if (state is UsersLoading || state is UserSaving) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is UsersError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: TmzColors.error),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.failure.message}',
                            style: TmzTextStyles.body
                                .copyWith(color: TmzColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<UsersBloc>()
                                  .add(const LoadUsersEvent());
                            },
                            child: const Text('RETRY'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is UsersLoaded) {
                    if (state.users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: TmzColors.gray50),
                            const SizedBox(height: 16),
                            Text(
                              state.query.isNotEmpty
                                  ? 'No users match your search'
                                  : 'No users found',
                              style: TmzTextStyles.body
                                  .copyWith(color: TmzColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return _UsersTable(
                      users: state.users,
                      total: state.total,
                      onEdit: _showEditDialog,
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  final List<UserProfileModel> users;
  final int total;
  final void Function(UserProfileModel) onEdit;

  const _UsersTable({
    required this.users,
    required this.total,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DataTable(
            headingRowColor: WidgetStateProperty.all(TmzColors.gray90),
            columns: const [
              DataColumn(label: Text('Username')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Created')),
              DataColumn(label: Text('Actions')),
            ],
            rows: users.map((user) {
              return DataRow(
                cells: [
                  DataCell(Text(user.username)),
                  DataCell(Text(user.displayName)),
                  DataCell(_RoleBadge(role: user.role)),
                  DataCell(Text(_formatDate(user.createdAt))),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: 'Edit',
                      onPressed: () => onEdit(user),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '$total user${total == 1 ? '' : 's'}',
              style: TmzTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    final color = isAdmin ? TmzColors.tmzRed : TmzColors.gray50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
