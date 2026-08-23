import 'package:flutter/material.dart';

import '../data/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _filterRole;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _adminService.getAllUsers(role: _filterRole);
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _toggleBan(Map<String, dynamic> user) async {
    final isBanned = user['verification_status'] == 'REJECTED';
    if (isBanned) {
      await _adminService.unbanUser(user['id']);
    } else {
      await _adminService.banUser(user['id']);
    }
    await _loadUsers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBanned ? 'Usuario desbaneado' : 'Usuariobaneado'),
          backgroundColor: isBanned ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Usuarios'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterRole = value);
              _loadUsers();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todos')),
              const PopupMenuItem(value: 'PLAYER', child: Text('Jugadores')),
              const PopupMenuItem(value: 'TEAM', child: Text('Equipos')),
              const PopupMenuItem(value: 'ADMIN', child: Text('Admins')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No hay usuarios'))
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isBanned = user['verification_status'] == 'REJECTED';
                      final role = user['role'] ?? 'UNKNOWN';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isBanned ? Colors.red : const Color(0xFF1B5E20),
                          child: Text(
                            (user['full_name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user['full_name'] ?? 'Sin nombre'),
                        subtitle: Text(
                          '${user['email'] ?? '-'} • $role',
                          style: TextStyle(
                            color: isBanned ? Colors.red : Colors.grey,
                          ),
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              child: ListTile(
                                leading: Icon(
                                  isBanned ? Icons.check_circle : Icons.block,
                                  color: isBanned ? Colors.green : Colors.red,
                                ),
                                title: Text(isBanned ? 'Desbanear' : 'Banear'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              onTap: () => _toggleBan(user),
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
