import 'package:flutter/material.dart';

import '../data/rating_service.dart';

class RateScreen extends StatefulWidget {
  final String reservationId;
  final String raterId;
  final String ratedId;
  final String ratedName;

  const RateScreen({
    super.key,
    required this.reservationId,
    required this.raterId,
    required this.ratedId,
    required this.ratedName,
  });

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  final _ratingService = RatingService();
  bool _isSubmitting = false;

  int _score = 0;
  int _punctuality = 0;
  int _behavior = 0;
  int _skillLevel = 0;
  int _compliance = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_score == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una calificación general'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _ratingService.submitRating(
        reservationId: widget.reservationId,
        raterId: widget.raterId,
        ratedId: widget.ratedId,
        score: _score,
        punctuality: _punctuality > 0 ? _punctuality : null,
        behavior: _behavior > 0 ? _behavior : null,
        skillLevel: _skillLevel > 0 ? _skillLevel : null,
        compliance: _compliance > 0 ? _compliance : null,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calificación enviada'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calificar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Califica a ${widget.ratedName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Calificación general',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _StarRating(
              rating: _score,
              onChanged: (v) => setState(() => _score = v),
            ),
            const SizedBox(height: 24),
            _CategoryRating(
              label: 'Puntualidad',
              rating: _punctuality,
              onChanged: (v) => setState(() => _punctuality = v),
            ),
            const SizedBox(height: 12),
            _CategoryRating(
              label: 'Comportamiento',
              rating: _behavior,
              onChanged: (v) => setState(() => _behavior = v),
            ),
            const SizedBox(height: 12),
            _CategoryRating(
              label: 'Nivel de juego',
              rating: _skillLevel,
              onChanged: (v) => setState(() => _skillLevel = v),
            ),
            const SizedBox(height: 12),
            _CategoryRating(
              label: 'Cumplimiento',
              rating: _compliance,
              onChanged: (v) => setState(() => _compliance = v),
            ),
            const SizedBox(height: 24),
            const Text(
              'Comentario (opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Cuéntanos tu experiencia...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enviar calificación', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _StarRating({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final index = i + 1;
        return IconButton(
          icon: Icon(
            index <= rating ? Icons.star : Icons.star_border,
            color: index <= rating ? Colors.amber : Colors.grey,
            size: 36,
          ),
          onPressed: () => onChanged(index),
        );
      }),
    );
  }
}

class _CategoryRating extends StatelessWidget {
  final String label;
  final int rating;
  final ValueChanged<int> onChanged;

  const _CategoryRating({
    required this.label,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(color: Colors.grey[600])),
        ),
        Expanded(
          child: Row(
            children: List.generate(5, (i) {
              final index = i + 1;
              return GestureDetector(
                onTap: () => onChanged(index),
                child: Icon(
                  index <= rating ? Icons.star : Icons.star_border,
                  color: index <= rating ? Colors.amber : Colors.grey,
                  size: 28,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
