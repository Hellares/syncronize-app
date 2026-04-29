/// Tipo de nota a emitir. Se mapea 1:1 con el backend.
enum TipoNota {
  notaCredito('NOTA_CREDITO', 'Nota de Crédito'),
  notaDebito('NOTA_DEBITO', 'Nota de Débito');

  final String backendValue;
  final String label;
  const TipoNota(this.backendValue, this.label);
}
