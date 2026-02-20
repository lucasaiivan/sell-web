import 'dart:math';
import 'package:sellweb/core/services/demo_account/data/demo_config.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/core/services/demo_account/generators/sales_demo_generator.dart';
import 'package:sellweb/core/services/demo_account/generators/users_demo_generator.dart';

/// Generador de datos demo para arqueos de caja
///
/// **Responsabilidad:**
/// - Generar estados de caja coherentes con tickets generados
/// - Calcular métricas realistas (efectivo, flujos, balance)
/// - Distribuir vendedores entre arqueos
class CashDemoGenerator {
  CashDemoGenerator._();

  // ==========================================
  // ARQUEOS DE CAJA
  // ==========================================

  /// Genera estados de caja para los últimos N días (configurable)
  ///
  /// **Retorna:** Lista de arqueos con:
  /// - Arqueos diarios coherentes
  /// - Flujos de caja realistas (ingresos/egresos)
  /// - Métricas calculadas a partir de tickets del día
  /// - Balance con pequeñas diferencias realistas
  /// Genera estados de caja para el último año con múltiples turnos por día
  ///
  /// **Retorna:** Lista de arqueos (~1200 registros) con:
  /// - ~3-5 turnos por día
  /// - Metadatos realistas (observaciones variadas)
  /// - Flujos de caja diversificados
  static List<CashRegister> generateDemoCashRegisters() {
    final cashRegisters = <CashRegister>[];
    // Usar tickets anuales para tener cobertura completa
    final tickets = SalesDemoGenerator.generateDemoTickets(scope: DemoTicketScope.annual);
    final users = UsersDemoGenerator.generateDemoAdminUsers();
    final activeUsers = users.where((u) => !u.inactivate).toList();
    final random = Random(kDemoRandomSeed);
    
    final now = DateTime.now();

    // Generar un arqueo por día (últimos 365 días)
    for (int day = 365; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));
      
      // Determinar cantidad de turnos para este día (2 a 4)
      // Días de fin de semana pueden tener más turnos o diferentes
      final shiftsCount = 2 + random.nextInt(3); 
      
      // Definir horarios de turnos aproximados
      final shifts = _generateShiftsForDate(date, shiftsCount);
      
      // Tickets de este día
      final dayTickets = tickets.where((t) {
        final ticketDate = t.creation.toDate();
        return ticketDate.year == date.year &&
               ticketDate.month == date.month &&
               ticketDate.day == date.day;
      }).toList();

      for (int i = 0; i < shifts.length; i++) {
        final shift = shifts[i];
        final opening = shift['start']!;
        final closing = shift['end']!;
        
        // Filtrar tickets que caen en este turno
        final shiftTickets = dayTickets.where((t) {
          final ticketDate = t.creation.toDate();
          return ticketDate.isAfter(opening) && ticketDate.isBefore(closing); 
        }).toList();

        // Calcular métricas del turno
        final totalSales = shiftTickets.length;
        final billing = shiftTickets.fold<double>(
          0.0,
          (sum, t) => sum + t.getTotalPrice,
        );

        // Efectivo inicial (turno mañana empieza con base, otros con remanente o base)
        final initialCash = i == 0 
            ? (kDemoMinInitialCash + random.nextDouble() * 50.0)
            : (kDemoMinInitialCash + random.nextDouble() * 200.0); // Simula cambio dejado
        
        // Generar flujos de caja
        final cashInFlows = _generateCashInFlows(random, opening, closing);
        final cashOutFlows = _generateCashOutFlows(random, opening, closing);

        final cashInTotal = cashInFlows.fold<double>(0.0, (sum, f) => sum + (f['amount'] as double));
        final cashOutTotal = cashOutFlows.fold<double>(0.0, (sum, f) => sum + (f['amount'] as double));

        // Balance
        final expectedBalance = initialCash + billing + cashInTotal - cashOutTotal;
        // Simular pequeñas diferencias (human error)
        final diff = random.nextDouble() < 0.3 
            ? (random.nextDouble() * 5.0 * (random.nextBool() ? 1 : -1)) 
            : 0.0;
        final balance = expectedBalance + diff;

        final seller = activeUsers[random.nextInt(activeUsers.length)];
        
        // Nota aleatoria
        final note = _getRandomNote(random, diff);

        final cashRegister = CashRegister(
          id: 'demo_cash_${day.toString().padLeft(3, '0')}_${i + 1}',
          description: 'Caja ${i + 1} - ${date.day}/${date.month}/${date.year}',
          idUser: seller.id,
          nameUser: seller.name,
          initialCash: initialCash,
          opening: opening,
          closure: closing,
          sales: totalSales,
          annulledTickets: 0,
          billing: billing,
          discount: 0.0,
          cashInFlow: cashInTotal,
          cashOutFlow: cashOutTotal,
          expectedBalance: expectedBalance,
          balance: balance,
          cashInFlowList: cashInFlows,
          cashOutFlowList: cashOutFlows,
          note: note,
        );

        cashRegisters.add(cashRegister);
      }
    }

    return cashRegisters;
  }

  static List<Map<String, DateTime>> _generateShiftsForDate(DateTime date, int count) {
    final shifts = <Map<String, DateTime>>[];
    final baseTime = DateTime(date.year, date.month, date.day);
    
    // Configuración simple de turnos secuenciales
    // Turno 1: 08:00 - 13:00
    // Turno 2: 13:00 - 17:00
    // Turno 3: 17:00 - 22:00
    // Turno 4: 22:00 - 02:00 (+1) (Opcional)
    
    // Tiempos fijos para simplicidad y coherencia
    final hours = [8, 13, 17, 22]; // Puntos de quiebre
    
    for (int i = 0; i < count && i < hours.length - 1; i++) {
        shifts.add({
          'start': baseTime.add(Duration(hours: hours[i])),
          'end': baseTime.add(Duration(hours: hours[i+1])),
        });
    }
    
    // Si count > 3, agregar turno noche extendido si es necesario
    if (count > 3) {
       shifts.add({
          'start': baseTime.add(Duration(hours: 22)),
          'end': baseTime.add(Duration(hours: 23, minutes: 59)),
       });
    }

    return shifts;
  }

  static List<Map<String, dynamic>> _generateCashInFlows(Random random, DateTime start, DateTime end) {
    final count = random.nextInt(3); // 0-2 ingresos
    final flows = <Map<String, dynamic>>[];
    
    final descriptions = [
      'Reposición de cambio',
      'Ingreso por error cobro anterior',
      'Pago deuda cliente manual',
      'Aporte socio',
      'Cambio inicial adicional',
    ];

    for (int i = 0; i < count; i++) {
      flows.add({
        'amount': 10 + random.nextDouble() * 100,
        'description': descriptions[random.nextInt(descriptions.length)],
        'date': start.add(Duration(minutes: random.nextInt(end.difference(start).inMinutes))),
      });
    }
    return flows;
  }

  static List<Map<String, dynamic>> _generateCashOutFlows(Random random, DateTime start, DateTime end) {
    final count = random.nextInt(4); // 0-3 egresos
    final flows = <Map<String, dynamic>>[];
    
    final descriptions = [
      'Pago proveedor (Efectivo)',
      'Compra insumos limpieza',
      'Retiro parcial seguridad',
      'Pago taxi empleado',
      'Adelanto sueldo',
      'Compra librería',
      'Gastos varios caja chica',
    ];

    for (int i = 0; i < count; i++) {
      flows.add({
        'amount': 5 + random.nextDouble() * 50,
        'description': descriptions[random.nextInt(descriptions.length)],
        'date': start.add(Duration(minutes: random.nextInt(end.difference(start).inMinutes))),
      });
    }
    return flows;
  }

  static String? _getRandomNote(Random random, double diff) {
    if (diff.abs() > 0.5) {
      final diffStr = diff.toStringAsFixed(2);
      final notes = [
        'Diferencia de $diffStr sin justificar.',
        'No cuadra el cierre por $diffStr.',
        'Posible error en vuelto ($diffStr).',
        'Faltante/Sobrante de $diffStr revisado por supervisor.',
      ];
      return notes[random.nextInt(notes.length)];
    }
    
    if (random.nextDouble() > 0.7) return null; // 30% sin nota si cuadra

    final notes = [
      'Cierre conforme.',
      'Todo OK.',
      'Turno tranquilo.',
      'Se dejó cambio en caja.',
      'Sin novedades.',
      'Cierre supervisado.',
      'Recuento de billetes ok.',
    ];
    return notes[random.nextInt(notes.length)];
  }
}
