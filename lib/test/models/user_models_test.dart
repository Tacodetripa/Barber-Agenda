import 'package:flutter_test/flutter_test.dart';
import 'package:barber_agenda/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel Tests', () {

    // PRUEBA 1: Conversión a Map
    test('toMap() debe convertir UserModel a Map correctamente', () {
      // Arrange (Preparar)
      final user = UserModel(
        uid: 'test123',
        email: 'test@test.com',
        firstName: 'Juan',
        lastName: 'Pérez',
        role: UserRole.barber,
        createdAt: DateTime(2025, 1, 1),
      );

      // Act (Actuar)
      final map = user.toMap();

      // Assert (Verificar)
      expect(map['uid'], 'test123');
      expect(map['email'], 'test@test.com');
      expect(map['firstName'], 'Juan');
      expect(map['lastName'], 'Pérez');
      expect(map['role'], 'barber');
    });

    // PRUEBA 2: Conversión desde Map
    test('fromMap() debe crear UserModel desde Map correctamente', () {
      // Arrange
      final map = {
        'uid': 'test456',
        'email': 'maria@test.com',
        'firstName': 'María',
        'lastName': 'López',
        'role': 'client',
        'createdAt': Timestamp.fromDate(DateTime(2025, 1, 10)),
      };

      // Act
      final user = UserModel.fromMap(map);

      // Assert
      expect(user.uid, 'test456');
      expect(user.email, 'maria@test.com');
      expect(user.firstName, 'María');
      expect(user.role, UserRole.client);
      expect(user.fullName, 'María López'); // Verifica getter
    });

    // PRUEBA 3: Nombre completo
    test('fullName debe concatenar firstName y lastName', () {
      // Arrange
      final user = UserModel(
        uid: 'test789',
        email: 'pedro@test.com',
        firstName: 'Pedro',
        lastName: 'García Martínez',
        role: UserRole.barber,
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(user.fullName, 'Pedro García Martínez');
    });

    // PRUEBA 4: WorkingDays - Verifica si trabaja un día
    test('worksOnDay() debe retornar true si el día está en workingDays', () {
      // Arrange
      final user = UserModel(
        uid: 'test999',
        email: 'barber@test.com',
        firstName: 'Carlos',
        lastName: 'Ramírez',
        role: UserRole.barber,
        workingDays: ['monday', 'tuesday', 'wednesday'],
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(user.worksOnDay('monday'), true);
      expect(user.worksOnDay('sunday'), false);
    });
  });
}