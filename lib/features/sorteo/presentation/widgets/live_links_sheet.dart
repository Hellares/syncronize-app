import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/sorteo.dart';

/// Plataformas típicas de transmisión (el valor viaja tal cual al bot).
const _plataformas = ['FACEBOOK', 'TIKTOK', 'INSTAGRAM', 'YOUTUBE', 'OTRO'];

/// Sheet para pegar los links del LIVE del sorteo (Facebook, TikTok...).
/// Devuelve la lista a guardar (vacía = quitar todos) o null si cancela.
/// El bot de WhatsApp los comparte en el menú y en las confirmaciones.
Future<List<LiveLinkSorteo>?> showLiveLinksSheet({
  required BuildContext context,
  required List<LiveLinkSorteo> actuales,
}) {
  return showModalBottomSheet<List<LiveLinkSorteo>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LiveLinksSheet(actuales: actuales),
  );
}

class _LiveLinksSheet extends StatefulWidget {
  final List<LiveLinkSorteo> actuales;
  const _LiveLinksSheet({required this.actuales});

  @override
  State<_LiveLinksSheet> createState() => _LiveLinksSheetState();
}

class _LinkRow {
  String plataforma;
  final TextEditingController urlCtrl;
  _LinkRow(this.plataforma, String url)
      : urlCtrl = TextEditingController(text: url);
}

class _LiveLinksSheetState extends State<_LiveLinksSheet> {
  late final List<_LinkRow> _rows = widget.actuales.isEmpty
      ? [_LinkRow('FACEBOOK', '')]
      : widget.actuales
          .map((l) => _LinkRow(
              _plataformas.contains(l.plataforma) ? l.plataforma : 'OTRO',
              l.url))
          .toList();
  // El aviso de validación va inline: un snackbar quedaría tapado por el
  // propio sheet modal.
  String? _error;

  @override
  void dispose() {
    for (final r in _rows) {
      r.urlCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pegar(_LinkRow row) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final texto = (data?.text ?? '').trim();
    if (texto.isEmpty || !mounted) return;
    setState(() {
      row.urlCtrl.text = texto;
      _error = null;
    });
  }

  void _confirmar() {
    final links = <LiveLinkSorteo>[];
    for (final r in _rows) {
      var url = r.urlCtrl.text.trim();
      if (url.isEmpty) continue;
      // El cajero suele pegar sin el esquema ("fb.watch/abc").
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      if (!url.contains('.')) {
        setState(() => _error = 'Revisa el link de ${r.plataforma}: '
            'no parece una dirección válida');
        return;
      }
      links.add(LiveLinkSorteo(plataforma: r.plataforma, url: url));
    }
    Navigator.of(context).pop(links);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.sensors, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Links del LIVE',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Pega el link de tu transmisión — el bot se lo comparte a '
                'los participantes para que entren directo. Deja los '
                'campos vacíos para quitarlos.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              for (final row in _rows) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: row.plataforma,
                      isDense: true,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.blue1,
                          fontWeight: FontWeight.w600),
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final p in _plataformas)
                          DropdownMenuItem(
                            value: p,
                            child: Text(p,
                                style: const TextStyle(fontSize: 11)),
                          ),
                      ],
                      onChanged: (v) =>
                          setState(() => row.plataforma = v ?? 'OTRO'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        controller: row.urlCtrl,
                        label: 'Link del live',
                        hintText: 'https://fb.watch/…',
                        borderColor: AppColors.blue1,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Pegar',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.content_paste_rounded,
                          size: 17, color: AppColors.blue1),
                      onPressed: () => _pegar(row),
                    ),
                    if (_rows.length > 1)
                      IconButton(
                        tooltip: 'Quitar',
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.close,
                            size: 17, color: Colors.grey.shade500),
                        onPressed: () => setState(() {
                          _rows.remove(row);
                          // dispose diferido: el frame actual aún lo pinta.
                          WidgetsBinding.instance.addPostFrameCallback(
                              (_) => row.urlCtrl.dispose());
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (_rows.length < 4)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(
                        () => _rows.add(_LinkRow('TIKTOK', ''))),
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text('Agregar otra plataforma',
                        style: TextStyle(fontSize: 11)),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Text(
                    _error!,
                    style: TextStyle(
                        fontSize: 10.5, color: Colors.red.shade700),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      isOutlined: true,
                      borderColor: Colors.grey.shade400,
                      textColor: Colors.grey.shade700,
                      enableShadow: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Guardar links',
                      backgroundColor: AppColors.blue1,
                      textColor: Colors.white,
                      onPressed: _confirmar,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
