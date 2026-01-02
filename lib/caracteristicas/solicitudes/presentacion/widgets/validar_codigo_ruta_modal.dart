import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/solicitudes_vm.dart';

class ValidarCodigoRutaModal extends StatefulWidget {
  final String rutaId;
  final VoidCallback? onCodigoValido;

  const ValidarCodigoRutaModal({
    Key? key,
    required this.rutaId,
    this.onCodigoValido,
  }) : super(key: key);

  @override
  State<ValidarCodigoRutaModal> createState() => _ValidarCodigoRutaModalState();
}

class _ValidarCodigoRutaModalState extends State<ValidarCodigoRutaModal> {
  final _codigoController = TextEditingController();
  bool _validando = false;
  String? _error;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, colorPrimario.withOpacity(0.05)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorPrimario.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline, size: 48, color: colorPrimario),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ruta Privada',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Ingresa el código de acceso para ver esta ruta',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codigoController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: 'HAKU-2024-XXXX',
                hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorPrimario),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorPrimario, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                errorText: _error,
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _validando ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _validando ? null : _validarCodigo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimario,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _validando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Validar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validarCodigo() async {
    final codigo = _codigoController.text.trim();

    if (codigo.isEmpty) {
      setState(() => _error = 'Ingresa el código');
      return;
    }

    setState(() {
      _validando = true;
      _error = null;
    });

    final vm = context.read<SolicitudesVM>();
    final esValido = await vm.validarCodigoRuta(widget.rutaId, codigo);

    setState(() => _validando = false);

    if (esValido) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Código válido. Acceso concedido.'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onCodigoValido?.call();
      }
    } else {
      setState(() => _error = 'Código incorrecto');
      _codigoController.clear();
    }
  }

  // Unused static method removed
}
