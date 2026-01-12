import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';

class OfertaCountdownTimer extends StatefulWidget {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  const OfertaCountdownTimer({
    super.key,
    this.fechaInicio,
    this.fechaFin,
  });

  @override
  State<OfertaCountdownTimer> createState() => _OfertaCountdownTimerState();
}

class _OfertaCountdownTimerState extends State<OfertaCountdownTimer> {
  Timer? _timer;
  Duration? _timeRemaining;
  bool _isOfertaActive = false;
  bool _isOfertaExpired = false;

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    if (widget.fechaFin == null) {
      setState(() {
        _timeRemaining = null;
        _isOfertaActive = false;
        _isOfertaExpired = false;
      });
      return;
    }

    final now = DateTime.now();
    final fechaInicio = widget.fechaInicio ?? now;

    // Verificar si la oferta ya comenzó
    if (now.isBefore(fechaInicio)) {
      // La oferta aún no comienza
      setState(() {
        _timeRemaining = fechaInicio.difference(now);
        _isOfertaActive = false;
        _isOfertaExpired = false;
      });
    } else if (now.isAfter(widget.fechaFin!)) {
      // La oferta ya expiró
      setState(() {
        _timeRemaining = Duration.zero;
        _isOfertaActive = false;
        _isOfertaExpired = true;
      });
    } else {
      // La oferta está activa
      setState(() {
        _timeRemaining = widget.fechaFin!.difference(now);
        _isOfertaActive = true;
        _isOfertaExpired = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeRemaining();

      // Si la oferta expiró, detener el timer
      if (_isOfertaExpired) {
        timer.cancel();
      }
    });
  }

  String _formatTimeUnit(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    if (_timeRemaining == null) {
      return const SizedBox.shrink();
    }

    if (_isOfertaExpired) {
      return _buildExpiredMessage();
    }

    final days = _timeRemaining!.inDays;
    final hours = _timeRemaining!.inHours % 24;
    final minutes = _timeRemaining!.inMinutes % 60;
    final seconds = _timeRemaining!.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 14,
              color: _isOfertaActive ? AppColors.blue1 : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            if (!_isOfertaActive)
              AppSubtitle(
                'Comienza en:',
                fontSize: 10,
                color: Colors.grey[700],
              )
            else
              AppSubtitle(
                'Termina en:',
                fontSize: 10,
                color: Colors.grey[700],
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeUnit(days.toString(), 'días'),
            _buildTimeSeparator(),
            _buildTimeUnit(_formatTimeUnit(hours), 'hrs'),
            _buildTimeSeparator(),
            _buildTimeUnit(_formatTimeUnit(minutes), 'min'),
            _buildTimeSeparator(),
            _buildTimeUnit(_formatTimeUnit(seconds), 'seg'),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _isOfertaActive ? AppColors.blue1 : Colors.grey[700],
            height: 1.0,
          ),
        ),
        // const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _isOfertaActive ? AppColors.orange : Colors.grey[600],
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildExpiredMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Oferta finalizada',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
