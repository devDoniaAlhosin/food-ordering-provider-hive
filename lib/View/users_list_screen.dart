import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Model/app_user.dart';
import '../Provider/user_provider.dart';
import '../extensions/string_validators.dart';
import '../extensions/text_form_field_extensions.dart';
import '../theme/app_theme.dart';

/// Admin-only Firestore users list with create / edit / delete.
class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final users = context.read<UserProvider>();
      if (users.isAdmin) {
        users.startWatchingUsers();
      }
    });
  }

  Future<void> _openEditor({AppUser? existing}) async {
    final result = await showModalBottomSheet<_UserFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _UserFormSheet(existing: existing),
        );
      },
    );
    if (result == null || !mounted) return;

    final users = context.read<UserProvider>();
    final bool ok;
    if (existing == null) {
      ok = await users.createUserWithAuth(
        email: result.email,
        password: result.password!,
        fullName: result.fullName,
        phone: result.phone,
        address: result.address,
        role: result.role,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'User created. You are now signed in as that user.'
                : (users.errorMessage ?? 'Could not create user'),
          ),
        ),
      );
      if (ok) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      ok = await users.updateUser(
        existing.copyWith(
          fullName: result.fullName,
          phone: result.phone,
          address: result.address,
          role: result.role,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'User updated' : (users.errorMessage ?? 'Could not update'),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(AppUser user) async {
    final users = context.read<UserProvider>();
    final wasSelf = users.currentProfile?.uid == user.uid;
    final passwordController = TextEditingController();
    var obscure = true;

    final result = await showDialog<_DeleteConfirmResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(wasSelf ? 'Delete your account?' : 'Delete user?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wasSelf
                        ? 'This removes your Firestore profile and Firebase Auth account.'
                        : 'Remove ${user.fullName} from Firestore?',
                  ),
                  if (wasSelf) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Confirm with password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() => obscure = !obscure);
                          },
                          icon: Icon(
                            obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (wasSelf && passwordController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(
                      dialogContext,
                      _DeleteConfirmResult(
                        confirmed: true,
                        password: wasSelf ? passwordController.text : null,
                      ),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
    passwordController.dispose();
    if (result == null || !result.confirmed || !mounted) return;

    final ok = await users.deleteUser(
      user.uid,
      password: result.password,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'User deleted' : (users.errorMessage ?? 'Could not delete'),
        ),
      ),
    );
    if (ok && wasSelf) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>();
    final theme = Theme.of(context);

    if (!users.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage users')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Admins only',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Each user manages their own account from My profile. '
                  'Only an admin can manage all users.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage users'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => users.refreshUsers(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add user'),
      ),
      body: users.isLoadingUsers && users.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : users.users.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No users in Firestore yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Register or tap Add user to create one.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: users.users.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = users.users[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: user.isAdmin
                              ? theme.colorScheme.primaryContainer
                              : AppTheme.peach,
                          foregroundColor: theme.colorScheme.primary,
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          [
                            user.email,
                            user.role.firestoreValue,
                            if (user.phone.isNotEmpty) user.phone,
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _openEditor(existing: user),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => _confirmDelete(user),
                              icon: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _DeleteConfirmResult {
  const _DeleteConfirmResult({
    required this.confirmed,
    this.password,
  });

  final bool confirmed;
  final String? password;
}

class _UserFormResult {
  const _UserFormResult({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    this.password,
  });

  final String fullName;
  final String email;
  final String phone;
  final String address;
  final UserRole role;
  final String? password;
}

class _UserFormSheet extends StatefulWidget {
  const _UserFormSheet({this.existing});

  final AppUser? existing;

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  final _passwordController = TextEditingController();
  bool _obscure = true;
  late UserRole _role;

  bool get _isCreate => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.fullName ?? '');
    _emailController = TextEditingController(text: e?.email ?? '');
    _phoneController = TextEditingController(text: e?.phone ?? '');
    _addressController = TextEditingController(text: e?.address ?? '');
    _role = e?.role ?? UserRole.user;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _UserFormResult(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        role: _role,
        password: _isCreate ? _passwordController.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isCreate ? 'Add user' : 'Edit user',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              AppTextFormField.fullName(controller: _nameController),
              const SizedBox(height: 12),
              if (_isCreate) ...[
                AppTextFormField.email(controller: _emailController),
                const SizedBox(height: 12),
                AppTextFormField.password(
                  controller: _passwordController,
                  obscureText: _obscure,
                  onToggleVisibility: () {
                    setState(() => _obscure = !_obscure);
                  },
                  textInputAction: TextInputAction.next,
                ),
              ] else
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: UserRole.user,
                    child: Text('user'),
                  ),
                  DropdownMenuItem(
                    value: UserRole.admin,
                    child: Text('admin'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _role = value);
                },
              ),
              const SizedBox(height: 12),
              AppTextFormField.phone(
                controller: _phoneController,
                required: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    value.maxLengthValidator(120, fieldName: 'Address'),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _submit,
                child: Text(_isCreate ? 'Create user' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
