import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/barbershop_provider.dart';

// Screens
import 'screens/auth/welcome_screen.dart';
import 'screens/client/client_home_screen.dart';
import 'screens/barber/barber_home_screen.dart';
import 'screens/superadmin/superadmin_home_screen.dart';
import 'screens/splash_screen.dart';

// Models
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error al inicializar Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => BarbershopProvider()),
      ],
      child: Consumer<AuthProvider>(  // ← AGREGAR CONSUMER AQUÍ
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Barber Agenda',
            debugShowCheckedModeBanner: false,

            // TEMA CLARO (Light Mode) - Premium
            theme: ThemeData(
              useMaterial3: true,

              // Paleta de colores Premium
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1A1A2E), // Negro azulado
                primary: const Color(0xFF1A1A2E),
                secondary: const Color(0xFFC5A572), // Oro viejo
                tertiary: const Color(0xFFE94560), // Rojo elegante
                surface: Colors.white,
                background: const Color(0xFFF5F5F5),
                error: const Color(0xFFE94560),
              ),

              // AppBar
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                backgroundColor: Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                iconTheme: IconThemeData(color: Colors.white),
              ),

              // Cards
              cardTheme: CardThemeData(  // ← ARREGLADO
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
              ),

              // Botones elevados (Filled Buttons)
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Botones con borde (Outlined Buttons)
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A2E),
                  side: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Botones de texto (Text Buttons)
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A2E),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // FAB (Floating Action Button)
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color(0xFFC5A572), // Oro
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),

              // Chips
              chipTheme: ChipThemeData(
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF1A1A2E),
                secondarySelectedColor: const Color(0xFFC5A572),
                disabledColor: const Color(0xFFF5F5F5),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E), // ← Texto oscuro por defecto
                ),
                secondaryLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white, // ← Texto blanco cuando está seleccionado
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(
                    color: Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                checkmarkColor: Colors.white,
                brightness: Brightness.light,
              ),

              // Inputs (TextField)
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE94560), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),

              // Navigation Bar
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Colors.white,
                elevation: 3,
                indicatorColor: const Color(0xFF1A1A2E).withOpacity(0.15),
                labelTextStyle: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    );
                  }
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF757575),
                  );
                }),
                iconTheme: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const IconThemeData(color: Color(0xFF1A1A2E));
                  }
                  return const IconThemeData(color: Color(0xFF757575));
                }),
              ),

              // Tipografía
              fontFamily: 'Roboto',
              textTheme: const TextTheme(
                headlineLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                headlineMedium: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                headlineSmall: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
                titleLarge: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
                titleMedium: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
                bodyLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF424242),
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF424242),
                ),
              ),

              // Divisores
              dividerColor: const Color(0xFFE0E0E0),
              dividerTheme: const DividerThemeData(
                thickness: 1,
                space: 1,
                color: Color(0xFFE0E0E0),
              ),
            ),

            // TEMA OSCURO (Dark Mode) - Premium Dark
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,

              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1A1A2E),
                brightness: Brightness.dark,
                primary: const Color(0xFFC5A572), // Oro en dark mode
                secondary: const Color(0xFF1A1A2E),
                tertiary: const Color(0xFFE94560),
                surface: const Color(0xFF1E1E1E),
                background: const Color(0xFF121212),
                error: const Color(0xFFE94560),
              ),

              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                backgroundColor: Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
              ),

              cardTheme: CardThemeData(  // ← ARREGLADO
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: const Color(0xFF1E1E1E),
              ),

              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC5A572), // Oro
                  foregroundColor: const Color(0xFF1A1A2E),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Modo del tema (puede cambiar entre light y dark)
            themeMode: ThemeMode.light, // Cambiar a ThemeMode.dark para modo oscuro

            home: const SplashScreen(
              nextScreen: AuthWrapper(),
            ),
          );
        },
      ),
    );
  }
}

// Widget que maneja la navegación según el estado de autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AppointmentProvider>(
      builder: (context, authProvider, appointmentProvider, _) {
        // Si está cargando, mostrar loading
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si no está autenticado, limpiar y mostrar bienvenida
        if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
          // Limpiar citas al cerrar sesión
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appointmentProvider.clearAppointments();
          });
          return const WelcomeScreen();
        }

        // Usuario autenticado - cargar sus datos
        final user = authProvider.currentUser!;

        // Cargar citas según el rol
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('👤 Usuario: ${user.email} (${user.role.name})');

          switch (user.role) {
            case UserRole.client:
              print('📱 Cargando citas del cliente...');
              appointmentProvider.loadClientAppointments(user.uid);
              break;
            case UserRole.barber:
              print('💈 Cargando citas del barbero...');
              appointmentProvider.loadBarberAppointments(user.uid);
              break;
            case UserRole.superadmin:
              print('👑 Cargando todas las citas...');
              appointmentProvider.loadAllAppointments();
              context.read<BarbershopProvider>().loadBarbershops();
              break;
          }
        });

        // Redirigir según el rol
        switch (user.role) {
          case UserRole.superadmin:
            return const SuperAdminHomeScreen();
          case UserRole.barber:
            return const BarberHomeScreen();
          case UserRole.client:
            return const ClientHomeScreen();
        }
      },
    );
  }
}