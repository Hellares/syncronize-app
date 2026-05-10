import 'package:syncronize/features/servicio/domain/entities/componente.dart';
import 'package:syncronize/features/servicio/domain/entities/orden_servicio.dart';

/// Fixture determinístico de OrdenServicio para golden tests.
class OrdenServicioFixture {
  OrdenServicioFixture._();

  static final _creadoEn = DateTime.utc(2026, 1, 15, 9, 0, 0);
  static final _actualizadoEn = DateTime.utc(2026, 1, 15, 9, 0, 5);
  static final _fechaEntrega = DateTime.utc(2026, 1, 22, 18, 0, 0);

  /// Orden con 1 componente y un cliente persona.
  static OrdenServicio buildSimple() {
    final tipoComp = const TipoComponente(
      id: 'tc_001',
      nombre: 'Disco Duro',
      categoria: 'ALMACENAMIENTO',
      esGlobal: true,
    );
    final componente = Componente(
      id: 'c_001',
      empresaId: 'emp_test',
      tipoComponenteId: 'tc_001',
      codigo: 'DD-1TB-WD',
      marca: 'Western Digital',
      modelo: 'Blue 1TB',
      tipoComponente: tipoComp,
    );

    return OrdenServicio(
      id: 'os_test_001',
      empresaId: 'emp_test',
      clienteId: 'cli_test',
      tecnicoId: 'tec_test',
      sedeId: 'sede_test',
      codigo: 'OS-2026-00001',
      tipoServicio: 'REPARACION',
      prioridad: 'NORMAL',
      tipoEquipo: 'LAPTOP',
      marcaEquipo: 'Dell',
      numeroSerie: 'SN12345678',
      descripcionProblema: 'No prende, posible falla de fuente.',
      costoTotal: 250.00,
      adelanto: 100.00,
      tiempoEstimado: 48,
      fechaEntrega: _fechaEntrega,
      estado: 'EN_DIAGNOSTICO',
      estadoDiagnostico: 'PENDIENTE',
      notas: 'Cliente reporta golpe reciente.',
      condicionEquipo: 'Pantalla con rayadura leve',
      origenOrden: 'CLIENTE_FINAL',
      creadoEn: _creadoEn,
      actualizadoEn: _actualizadoEn,
      cliente: const OrdenCliente(
        id: 'cli_test',
        nombre: 'Juan Carlos',
        apellido: 'Perez Garcia',
        email: 'juan@test.com',
        telefono: '999888777',
        documentoNumero: '12345678',
      ),
      tecnico: const OrdenTecnico(
        id: 'tec_test',
        nombre: 'Maria',
        apellido: 'Lopez',
      ),
      componentes: [
        OrdenComponente(
          id: 'oc_001',
          ordenServicioId: 'os_test_001',
          componenteId: 'c_001',
          tipoAccion: 'CAMBIO',
          estadoComponente: 'INGRESADO',
          descripcionAccion: 'Reemplazo de disco duro',
          costoAccion: 80.00,
          costoRepuestos: 170.00,
          garantiaMeses: 6,
          componente: componente,
        ),
      ],
    );
  }
}
