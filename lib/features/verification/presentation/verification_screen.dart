import 'package:flutter/material.dart';

import '../data/verification_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _verificationService = VerificationService();
  IdentityDocument? _document;
  bool _isLoading = true;
  bool _isSubmitting = false;

  final _documentNumberController = TextEditingController();
  String _selectedDocType = 'CEDULA_CIUDADANIA';

  final _docTypes = {
    'CEDULA_CIUDADANIA': 'Cédula de Ciudadanía',
    'CEDULA_EXTRANJERIA': 'Cédula de Extranjería',
    'PASAPORTE': 'Pasaporte',
    'NIT': 'NIT',
    'RUT': 'RUT',
  };

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    final doc = await _verificationService.getMyDocument();
    setState(() {
      _document = doc;
      if (doc != null) {
        _selectedDocType = doc.documentType;
        _documentNumberController.text = doc.documentNumber;
      }
      _isLoading = false;
    });
  }

  Future<void> _submitDocument() async {
    if (_documentNumberController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await _verificationService.submitDocument(
        documentType: _selectedDocType,
        documentNumber: _documentNumberController.text.trim(),
      );

      await _loadDocument();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento enviado para revisión'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Color _getStatusColor() {
    switch (_document?.status) {
      case 'VERIFIED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_document?.status) {
      case 'VERIFIED':
        return 'Verificado';
      case 'PENDING':
        return 'En revisión';
      case 'REJECTED':
        return 'Rechazado';
      default:
        return 'Sin verificar';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verificación de Identidad')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Estado de verificación',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_document?.rejectionReason != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Motivo: ${_document!.rejectionReason}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Datos del documento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDocType,
              decoration: const InputDecoration(
                labelText: 'Tipo de documento',
                border: OutlineInputBorder(),
              ),
              items: _docTypes.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedDocType = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _documentNumberController,
              decoration: const InputDecoration(
                labelText: 'Número de documento',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tip: Sube fotos de tu documento en la sección de perfil para completar la verificación.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitDocument,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Enviando...' : 'Enviar para revisión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
