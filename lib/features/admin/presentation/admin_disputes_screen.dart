import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/admin_service.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _disputes = [];
  bool _isLoading = true;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    setState(() => _isLoading = true);
    final data = await _adminService.getAllDisputes(status: _filterStatus);
    setState(() {
      _disputes = data;
      _isLoading = false;
    });
  }

  Future<void> _resolveDispute(Map<String, dynamic> dispute) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolver disputa'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escribe la resolución...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: const Text('Resolver'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final userId = await _adminService.isAdmin() ? '' : '';
      await _adminService.resolveDispute(
        disputeId: dispute['id'],
        resolvedBy: userId,
        resolution: result,
      );
      await _loadDisputes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disputa resuelta'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN': return Colors.orange;
      case 'RESOLVED': return Colors.green;
      case 'CLOSED': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Disputas'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterStatus = value);
              _loadDisputes();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todas')),
              const PopupMenuItem(value: 'OPEN', child: Text('Abiertas')),
              const PopupMenuItem(value: 'RESOLVED', child: Text('Resueltas')),
              const PopupMenuItem(value: 'CLOSED', child: Text('Cerradas')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _disputes.isEmpty
              ? const Center(child: Text('No hay disputas'))
              : RefreshIndicator(
                  onRefresh: _loadDisputes,
                  child: ListView.builder(
                    itemCount: _disputes.length,
                    itemBuilder: (context, index) {
                      final d = _disputes[index];
                      final status = d['status'] ?? '';
                      final statusColor = _getStatusColor(status);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      d['reason'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (d['description'] != null && d['description'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(d['description'], style: TextStyle(color: Colors.grey[700])),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    d['opener_profile']?['full_name'] ?? 'Anónimo',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('dd/MM HH:mm').format(DateTime.parse(d['created_at'])),
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              ),
                              if (status == 'OPEN') ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _resolveDispute(d),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Resolver'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B5E20),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                              if (d['resolution'] != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          d['resolution'],
                                          style: const TextStyle(color: Colors.green, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
