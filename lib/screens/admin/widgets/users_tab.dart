import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/club_provider.dart';
import '../../../screens/chat/direct_chat_screen.dart';
import '../../../services/club_detail_edit_request_service.dart';
import '../../../services/direct_chat_service.dart';
import '../../../widgets/app_search_field.dart';
import '../../../widgets/confirm_action_dialog.dart';
import '../../../widgets/identity_avatar.dart';
import 'role_chip.dart';

class UsersTab extends StatefulWidget {
  final FirebaseFirestore db;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  const UsersTab({
    super.key,
    required this.db,
    required this.onDelete,
  });

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final _searchCtrl = TextEditingController();
  final _detailEditRequests = ClubDetailEditRequestService();
  final _directChats = DirectChatService();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFEF4444);
      case 'manager':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Map<String, dynamic> _chatTarget(Map<String, dynamic> user) {
    return {
      'uid': user['id'] as String? ?? '',
      'name': user['name'] as String? ?? 'User',
      'photoBase64': user['photo_base64'] as String?,
      'gender': user['gender'] as String?,
      'managedClubId': user['managed_club_id'] as String?,
      'messagePrivacy': user['message_privacy'] as String? ?? 'everyone',
    };
  }

  String _clubName(String clubId) {
    final club = context.read<ClubProvider>().getById(clubId);
    return club?.name ?? 'Club';
  }

  Future<void> _openChat(Map<String, dynamic> user) async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    try {
      final chatId = await _directChats.startChat(
        currentUser: currentUser,
        target: _chatTarget(user),
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DirectChatScreen(
            chatId: chatId,
            title: user['name'] as String? ?? 'Chat',
            user: currentUser,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open chat: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _grantEditPermission(Map<String, dynamic> manager) async {
    final currentUser = context.read<AuthProvider>().currentUser;
    final clubId = manager['managed_club_id'] as String? ?? '';
    if (currentUser == null || clubId.isEmpty) return;

    final clubName = _clubName(clubId);
    final result = await showDialog<_GrantEditPermissionResult>(
      context: context,
      builder: (_) => _GrantEditPermissionDialog(
        managerName: manager['name'] as String? ?? 'Club manager',
        clubName: clubName,
      ),
    );
    if (result == null) return;

    try {
      final expiresAt = await _detailEditRequests.grantManagerEditAccess(
        clubId: clubId,
        clubName: clubName,
        managerId: manager['id'] as String? ?? '',
        adminId: currentUser.id,
        minutes: result.minutes,
        managerName: manager['name'] as String? ?? '',
        fields: result.fields,
      );
      if (!mounted) return;
      final fieldSummary = ClubDetailEditField.describe(result.fields);
      final message = result.isPermanent
          ? 'Edit permission for $fieldSummary granted permanently.'
          : 'Edit permission granted until '
              '${TimeOfDay.fromDateTime(expiresAt).format(context)}.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not grant edit permission: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _revokeEditPermission(Map<String, dynamic> manager) async {
    final clubId = manager['managed_club_id'] as String? ?? '';
    final managerId = manager['id'] as String? ?? '';
    if (clubId.isEmpty || managerId.isEmpty) return;

    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Lock club profile edits?',
      message: 'Close edit access for ${manager['name'] ?? 'this manager'}?',
      confirmLabel: 'Lock',
      icon: Icons.lock_outline_rounded,
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    try {
      await _detailEditRequests.revokeManagerEditAccess(
        clubId: clubId,
        clubName: _clubName(clubId),
        managerId: managerId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Club profile editing locked.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not lock edit permission: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentUser = context.watch<AuthProvider>().currentUser;
    context.watch<ClubProvider>().clubs;

    return StreamBuilder<QuerySnapshot>(
      stream: widget.db.collection('profiles').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final q = _searchCtrl.text.toLowerCase();
        final users = docs
            .map((d) {
              final data = Map<String, dynamic>.from(
                d.data() as Map<String, dynamic>,
              );
              data['id'] = data['id'] as String? ?? d.id;
              return data;
            })
            .where((u) =>
                q.isEmpty ||
                (u['name'] as String? ?? '').toLowerCase().contains(q) ||
                (u['email'] as String? ?? '').toLowerCase().contains(q) ||
                (u['student_id'] as String? ?? '').toLowerCase().contains(q))
            .toList()
          ..sort((a, b) => (a['name'] as String? ?? '')
              .compareTo(b['name'] as String? ?? ''));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AppSearchField(
                controller: _searchCtrl,
                hintText: 'Search users...',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${users.length} users',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: snap.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? Center(
                          child: Text(
                            'No users found.',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: users.length,
                          itemBuilder: (_, i) {
                            final u = users[i];
                            final role = u['role'] as String? ?? 'student';
                            final userId = u['id'] as String? ?? '';
                            final managedClubId =
                                u['managed_club_id'] as String? ?? '';
                            final isManager =
                                role == 'manager' && managedClubId.isNotEmpty;
                            final canMessage =
                                currentUser != null && currentUser.id != userId;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: UserAvatar(
                                  photoBase64:
                                      u['photo_base64'] as String? ?? '',
                                  gender: u['gender'] as String? ?? 'male',
                                  radius: 20,
                                  backgroundColor:
                                      _roleColor(role).withValues(alpha: 0.15),
                                ),
                                title: Text(
                                  (u['name'] as String?) ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${u['email'] ?? ''} - ID: '
                                  '${u['student_id'] ?? '-'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RoleChip(role: role),
                                    const SizedBox(width: 4),
                                    _UserActionsMenu(
                                      user: u,
                                      isManager: isManager,
                                      canMessage: canMessage,
                                      detailEditRequests: _detailEditRequests,
                                      onMessage: () => _openChat(u),
                                      onGrant: () => _grantEditPermission(u),
                                      onRevoke: () => _revokeEditPermission(u),
                                      onDelete: () => widget.onDelete(u),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _UserActionsMenu extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isManager;
  final bool canMessage;
  final ClubDetailEditRequestService detailEditRequests;
  final VoidCallback onMessage;
  final VoidCallback onGrant;
  final VoidCallback onRevoke;
  final VoidCallback onDelete;

  const _UserActionsMenu({
    required this.user,
    required this.isManager,
    required this.canMessage,
    required this.detailEditRequests,
    required this.onMessage,
    required this.onGrant,
    required this.onRevoke,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final clubId = user['managed_club_id'] as String? ?? '';
    final managerId = user['id'] as String? ?? '';

    if (!isManager || clubId.isEmpty || managerId.isEmpty) {
      return _MenuButton(
        canMessage: canMessage,
        hasActiveEditPermission: false,
        loadingPermission: false,
        onMessage: onMessage,
        onGrant: onGrant,
        onRevoke: onRevoke,
        onDelete: onDelete,
        showManagerActions: false,
      );
    }

    return FutureBuilder<DateTime?>(
      future: detailEditRequests.activePermissionExpiresAt(
        clubId: clubId,
        managerId: managerId,
      ),
      builder: (context, snapshot) {
        return _MenuButton(
          canMessage: canMessage,
          hasActiveEditPermission: snapshot.data != null,
          loadingPermission: snapshot.connectionState == ConnectionState.waiting,
          onMessage: onMessage,
          onGrant: onGrant,
          onRevoke: onRevoke,
          onDelete: onDelete,
          showManagerActions: true,
        );
      },
    );
  }
}

class _MenuButton extends StatelessWidget {
  final bool canMessage;
  final bool hasActiveEditPermission;
  final bool loadingPermission;
  final bool showManagerActions;
  final VoidCallback onMessage;
  final VoidCallback onGrant;
  final VoidCallback onRevoke;
  final VoidCallback onDelete;

  const _MenuButton({
    required this.canMessage,
    required this.hasActiveEditPermission,
    required this.loadingPermission,
    required this.showManagerActions,
    required this.onMessage,
    required this.onGrant,
    required this.onRevoke,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<_UserAction>(
      tooltip: 'User actions',
      color: cs.surface,
      surfaceTintColor: cs.surfaceTint,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
      onSelected: (action) {
        switch (action) {
          case _UserAction.message:
            onMessage();
            break;
          case _UserAction.grantEdit:
            onGrant();
            break;
          case _UserAction.revokeEdit:
            onRevoke();
            break;
          case _UserAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _UserAction.message,
          enabled: canMessage,
          child: const _MenuRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Message',
          ),
        ),
        if (showManagerActions)
          PopupMenuItem(
            value: hasActiveEditPermission
                ? _UserAction.revokeEdit
                : _UserAction.grantEdit,
            enabled: !loadingPermission,
            child: _MenuRow(
              icon: hasActiveEditPermission
                  ? Icons.lock_outline_rounded
                  : Icons.lock_open_rounded,
              label: loadingPermission
                  ? 'Checking access...'
                  : hasActiveEditPermission
                      ? 'Lock club profile'
                      : 'Grant edit permission',
            ),
          ),
        PopupMenuItem(
          value: _UserAction.delete,
          child: _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Remove user',
            color: cs.error,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 18, color: effectiveColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: effectiveColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

enum _UserAction {
  message,
  grantEdit,
  revokeEdit,
  delete,
}

class _GrantEditPermissionResult {
  final int? minutes;
  final List<String> fields;

  const _GrantEditPermissionResult({
    required this.minutes,
    required this.fields,
  });

  bool get isPermanent => minutes == null;
}

class _GrantEditPermissionDialog extends StatefulWidget {
  final String managerName;
  final String clubName;

  const _GrantEditPermissionDialog({
    required this.managerName,
    required this.clubName,
  });

  @override
  State<_GrantEditPermissionDialog> createState() =>
      _GrantEditPermissionDialogState();
}

class _GrantEditPermissionDialogState
    extends State<_GrantEditPermissionDialog> {
  final _minutesCtrl = TextEditingController(text: '10');
  bool _permanent = false;
  bool _name = true;
  bool _description = true;
  bool _logo = true;
  String? _fieldError;
  String? _minutesError;

  List<String> get _fields => [
        if (_name) ClubDetailEditField.name,
        if (_description) ClubDetailEditField.description,
        if (_logo) ClubDetailEditField.logo,
      ];

  @override
  void dispose() {
    _minutesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final fields = _fields;
    if (fields.isEmpty) {
      setState(() => _fieldError = 'Select at least one field.');
      return;
    }

    if (_permanent) {
      Navigator.pop(
        context,
        _GrantEditPermissionResult(minutes: null, fields: fields),
      );
      return;
    }

    final minutes = int.tryParse(_minutesCtrl.text.trim());
    if (minutes == null || minutes <= 0) {
      setState(() => _minutesError = 'Enter a valid number of minutes.');
      return;
    }
    Navigator.pop(
      context,
      _GrantEditPermissionResult(minutes: minutes, fields: fields),
    );
  }

  Widget _fieldTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CheckboxListTile(
      value: value,
      controlAffinity: ListTileControlAffinity.leading,
      secondary: Icon(icon),
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      onChanged: (checked) {
        setState(() {
          onChanged(checked ?? false);
          _fieldError = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Row(
        children: [
          Icon(Icons.lock_open_rounded),
          SizedBox(width: 10),
          Expanded(child: Text('Grant edit permission')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Allow ${widget.managerName} to edit selected fields for '
            '${widget.clubName}.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 10),
          _fieldTile(
            title: 'Club name',
            icon: Icons.badge_outlined,
            value: _name,
            onChanged: (value) => _name = value,
          ),
          _fieldTile(
            title: 'Description',
            icon: Icons.notes_rounded,
            value: _description,
            onChanged: (value) => _description = value,
          ),
          _fieldTile(
            title: 'Logo image',
            icon: Icons.image_outlined,
            value: _logo,
            onChanged: (value) => _logo = value,
          ),
          if (_fieldError != null) ...[
            const SizedBox(height: 6),
            Text(_fieldError!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 14),
          SwitchListTile(
            value: _permanent,
            contentPadding: EdgeInsets.zero,
            title: const Text('Permanent access'),
            onChanged: (value) => setState(() {
              _permanent = value;
              _minutesError = null;
            }),
          ),
          TextField(
            controller: _minutesCtrl,
            enabled: !_permanent,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Minutes',
              prefixIcon: const Icon(Icons.timer_outlined),
              errorText: _minutesError,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Grant'),
        ),
      ],
    );
  }
}
