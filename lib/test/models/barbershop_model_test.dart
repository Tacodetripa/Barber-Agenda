import 'package:flutter_test/flutter_test.dart';
import 'package:barber_agenda/models/barbershop_model.dart';

void main() {
  group('BarbershopModel Tests', () {

    // PRUEBA 5: Crear barbería con datos válidos
    test('BarbershopModel se crea con datos válidos', () {
      final barbershop = BarbershopModel(
        id: 'shop001',
        name: 'BarberShop Test',
        address: 'Calle Falsa 123',
        ownerId: 'owner123',
        workingDays: ['monday', 'tuesday', 'wednesday'],
        openingTime: '09:00',
        closingTime: '18:00',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(barbershop.id, 'shop001');
      expect(barbershop.name, 'BarberShop Test');
      expect(barbershop.workingDays.length, 3);
      expect(barbershop.workingDays.contains('monday'), true);
    });

    // PRUEBA 6: toMap() incluye todos los campos
    test('toMap() incluye todos los campos requeridos', () {
      final barbershop = BarbershopModel(
        id: 'shop002',
        name: 'La Barbería',
        address: 'Av. Principal 456',
        ownerId: 'owner456',
        workingDays: ['monday', 'friday'],
        openingTime: '10:00',
        closingTime: '20:00',
        createdAt: DateTime(2025, 1, 5),
      );

      final map = barbershop.toMap();

      expect(map['name'], 'La Barbería');
      expect(map['openingTime'], '10:00');
      expect(map['closingTime'], '20:00');
      expect(map['workingDays'], ['monday', 'friday']);
    });
  });
}