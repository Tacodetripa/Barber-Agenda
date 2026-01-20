# 💈 BARBER AGENDA

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" />
  <img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white" />
</p>

## 📋 Descripción

**Barber Agenda** es una aplicación móvil multiplataforma desarrollada con Flutter que digitaliza la gestión de citas en barberías. Permite a clientes agendar citas 24/7, a barberos organizar su agenda diaria, y a administradores gestionar múltiples barberías desde un solo lugar.

### 🎯 Problema que resuelve

Las barberías tradicionalmente operan con métodos desorganizados:
- ❌ Agendas en papel que se pierden
- ❌ Citas por WhatsApp mezcladas con mensajes personales
- ❌ Doble agendamiento (dos clientes a la misma hora)
- ❌ Clientes sin confirmación de cita
- ❌ Barberos sin visibilidad de su día

**Barber Agenda soluciona todo esto** con una plataforma digital centralizada.

---

## 🎥 Video Demostración

### Pruebas Unitarias
> 📹 **[[Ver video de pruebas unitarias aquí]](https://drive.google.com/drive/folders/14YRmPp877Tg7JD9prlaKa3WN-i9Nl-fl?usp=sharing)**

---

## ✨ Características Principales

### 🔐 Sistema de Autenticación
- **Registro de usuarios** con email y contraseña
- **Inicio de sesión** seguro con Firebase Authentication
- **3 roles de usuario** con permisos diferenciados:
  - 👑 **SuperAdmin** (Administrador total)
  - ✂️ **Barbero** (Empleado/Independiente)
  - 👤 **Cliente** (Usuario final)
- **Recuperación de contraseña** vía email
- **Sesión persistente** (no requiere login cada vez)

### 👑 Panel de SuperAdmin
El SuperAdmin tiene control total sobre el sistema:

#### Gestión de Barberías
- ➕ **Crear barberías**:
  - Nombre del establecimiento
  - Dirección completa
  - Número de teléfono
  - Ubicación GPS (latitud y longitud)
  - Horarios de apertura y cierre
  
- 📋 **Listar todas las barberías**:
  - Vista de tarjetas con información resumida
  - Búsqueda por nombre o ciudad
  - Visualización de horarios

- ✏️ **Editar barberías**:
  - Actualizar cualquier información
  - Modificar horarios de operación
  
- 🗑️ **Eliminar barberías**:
  - Confirmación antes de eliminar
  - Validación de barberías con barberos asignados

#### Gestión de Barberos
- ➕ **Crear barberos**:
  - Datos personales (nombre, apellido, email)
  - Asignación a barbería específica
  - Creación automática de cuenta de acceso

- 📋 **Listar barberos**:
  - Lista de barberos existentes

- ✏️ **Editar barberos**:
  - Modificar información personal
  - Reasignar a otra barbería
  - Cambiar horarios de trabajo

- 🗑️ **Eliminar barberos**:
  - Validación de citas pendientes
  - Confirmación obligatoria

#### Dashboard de Estadísticas
- 📊 **Métricas en tiempo real**:
  - Total de barberías registradas
  - Total de barberos activos
  - Total de citas en el sistema
  
- 📈 **Gráfico de citas por estado**:
  - Pendientes (amarillo)
  - Confirmadas (azul)
  - Completadas (verde)
  - Canceladas (rojo)
  - Visualización con barra de progreso

- 📅 **Últimas 5 citas**:
  - Nombre del cliente
  - Barbero asignado
  - Fecha y hora
  - Estado actual
  - Ordenadas por fecha (más reciente primero)

#### Acciones Rápidas
- 🏢 Crear nueva barbería
- 👤 Crear nuevo barbero

#### Visualización de Todas las Citas
  
- 🔍 **Detalles de cada cita**:
  - Información del cliente
  - Barbero asignado
  - Barbería
  - Fecha y hora
  - Temas de conversación (si los hay)
  - Historial de cambios de estado

### ✂️ Panel del Barbero
Los barberos tienen acceso a funcionalidades enfocadas en su trabajo diario:

#### Dashboard Personal
- 📅 **Vista de "Citas de Hoy"**:
  - Lista ordenada por hora
  - Próxima cita destacada
  - Información del cliente
  - Hora exacta
  - Estado de la cita

- 📆 **Vista de "Próximas Citas"**:
  - Calendario con citas futuras
  - Agrupadas por fecha
  - Vista de semana y mes

#### Gestión de Citas
- ✅ **Marcar cita como completada**:
  - Botón visible solo cuando llega la hora
  - Confirmación antes de marcar
  - Actualización instantánea del estado

- ❌ **Cancelar citas**:
  - Solo citas pendientes/confirmadas
  - Requiere confirmación
  - Notificación al cliente (futura mejora)

- 📋 **Ver detalles completos**:
  - Datos del cliente (nombre, apellido, apodo)
  - Temas de conversación sugeridos
  - Notas adicionales
  - Hora de creación de la cita

#### Crear Citas (Walk-in)
- ➕ **Agendar para cliente sin app**:
  - Formulario rápido
  - Nombre del cliente
  - Seleccionar horario disponible
  - Notas opcionales
  - Creación inmediata

- ⏰ **Validación de horarios**:
  - Solo muestra horas disponibles
  - Respeta horarios ocupados
  - Previene doble agendamiento

#### Perfil del Barbero
- 👤 Ver información personal

### 👤 Panel del Cliente
Los clientes tienen una experiencia simple y directa:

#### Buscar Barberías
- 🔍 **Explorar barberías disponibles**:
  - Lista con información básica
  - Nombre
  - Dirección
  - Horarios de operación

#### Seleccionar Barbero
- 👨‍🦲 **Ver barberos disponibles**:
  - Lista de barberos de la barbería seleccionada
  - Nombre completo
  - Foto de perfil (futura mejora)
  - Calificación (futura mejora)

- ⭐ **Información de cada barbero**:
  - Horarios de trabajo

#### Agendar Cita
- 📅 **Seleccionar fecha**:
  - Calendario visual
  - Solo fechas futuras habilitadas

- ⏰ **Seleccionar hora**:
  - Solo horarios disponibles mostrados
  - Horarios ocupados **no aparecen**
  - Intervalos de 30, 40, 60 minutos
  - Respeta horarios de la barbería

- 📝 **Información adicional**:
  - Temas de conversación opcionales
  - Notas especiales

- ✅ **Confirmación**:
  - Resumen de la cita
  - Barbería, barbero, fecha, hora
  - Botón de confirmar
  - Creación instantánea

#### Mis Citas
- 📋 **Ver todas las citas**:
  - Próximas citas
  - Historial de citas pasadas
  - Estado de cada cita

- 🔔 **Cita del día**:
  - Destacada en pantalla principal
  - Información completa
  - Dirección de la barbería

- ❌ **Cancelar cita**:
  - Solo citas pendientes/confirmadas
  - Confirmación obligatoria
  - Actualización en tiempo real

#### Perfil del Cliente
- 👤 Ver información personal

---

## 🏗️ Arquitectura Técnica

### Stack Tecnológico

#### Frontend
- **Framework:** Flutter 3.x
- **Lenguaje:** Dart
- **State Management:** Provider
- **UI:** Material Design 3

#### Backend
- **BaaS:** Firebase
- **Autenticación:** Firebase Authentication
- **Base de Datos:** Cloud Firestore (NoSQL)
- **Hosting:** Firebase Hosting (Web)
- **Storage:** Cloud Storage (futuro, para fotos)

### Estructura del Proyecto

```
lib/
├── models/                            # Modelos de datos
│   ├── user_model.dart               # Usuario (cliente/barbero/admin)
│   ├── barbershop_model.dart         # Barbería
│   ├── appointment_model.dart        # Cita
│   └── working_hours.dart
│
├── providers/                         # State Management
│   ├── auth_provider.dart            # Autenticación
│   ├── barbershop_provider.dart      # Gestión de barberías
│   └── appointment_provider.dart     # Gestión de citas
│
├── services/                          # Servicios
│   ├── auth_service.dart             # Firebase Auth
│   └── firestore_service.dart        # Firestore CRUD
│
├── screens/                           # Pantallas
│   ├── auth/                         # Autenticación
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   │   └── welcome_screen.dart
│   │
│   ├── superadmin/                   # SuperAdmin
│   │   ├── barber_schedule_config_screen.dart
│   │   ├── create_barber_screen.dart
│   │   ├── create_barbershop_screen.dart
│   │   ├── edit_barber_screen.dart
│   │   ├── edit_barbershop_screen.dart
│   │   ├── manage_barbers_screen.dart
│   │   ├── manage_barbershops_screen.dart
│   │   └── superadmin_home_screen.dart
│   │
│   ├── barber/                       # Barbero
│   │   ├── barber_calendar_screen.dart
│   │   ├── barber_home_screen.dart
│   │   └── create_walkin_appointment_screen.dart
│   │
│   ├── client/                       # Cliente
│   │   ├── client_home_screen.dart
│   │   ├── create_appointment_screen.dart
│   │   ├── select_barebr_screen.dart
│   │   └── select_barbershop_screen.dart
│   │
│   ├── common/                       # location
│   │   └── barbershop_location_screen.dart
│   │
│   ├── shared/                       # detalles de la cita
│   │   ├── appointment_detail_screen.dart
│   │   └── edit_apointment_screen.dart
│   │
├── test.models/                           # Prueba Unitarias
│   ├── barbershop_model_test.dart
│   └── user_models_test.dart
│   │
├── utils/                           # Utilidades
│   ├── firebase_options.dart
│   ├── main.dart                      # punto de entrada
│
└── widgets/                             # Widgets
    ├── empty_state_widget.dart                # transiciones

├── firebase_options.dart
└── main.dart                         #Punto de entrada
```

---

## 🔄 Flujos de Uso

### Flujo 1: Cliente Agenda una Cita

```
1. Cliente abre app
2. Sistema verifica sesión (AuthProvider)
3. Si no está logueado → Pantalla de login
4. Login exitoso → Pantalla principal de cliente
5. Cliente presiona "Agendar Cita"
6. Sistema carga lista de barberías desde Firestore
7. Cliente selecciona barbería
8. Sistema carga barberos de esa barbería
9. Cliente selecciona barbero
10. Sistema muestra calendario
11. Cliente selecciona fecha
12. Sistema consulta citas existentes del barbero en esa fecha
13. Sistema filtra horarios ocupados
14. Cliente ve solo horarios disponibles
15. Cliente selecciona hora
16. Cliente llena notas y temas de conversación (opcional)
17. Cliente presiona "Confirmar Cita"
18. Sistema valida datos
19. Sistema crea documento en Firestore (appointments)
20. Sistema actualiza UI en tiempo real
21. Barbero ve nueva cita instantáneamente en su dashboard
22. Cliente ve confirmación exitosa
```

### Flujo 2: Barbero Crea Cita Walk-in

```
1. Barbero abre app
2. Dashboard muestra citas del día
3. Llega cliente sin cita
4. Barbero presiona "Crear Cita"
5. Formulario de nueva cita se abre
6. Barbero ingresa nombre del cliente
7. Sistema muestra solo horarios disponibles (hoy)
8. Barbero selecciona hora libre
9. Barbero agrega notas
10. Barbero presiona "Crear"
11. Sistema valida que hora siga disponible
12. Sistema crea cita con status "confirmed"
13. Cita aparece en dashboard del barbero
14. Cliente (si tiene app) ve cita en "Mis Citas"
```

### Flujo 3: SuperAdmin Crea Barbería y Barbero

```
1. SuperAdmin abre app
2. Dashboard con estadísticas se carga
3. SuperAdmin presiona "Crear Barbería"
4. Formulario de barbería se abre
5. SuperAdmin llena datos:
   - Nombre
   - Dirección
   - Teléfono
   - Horarios (apertura/cierre)
6. Sistema valida datos
7. Sistema crea documento en Firestore (barbershops)
8. Barbería aparece en lista
9. SuperAdmin presiona "Crear Barbero"
10. Formulario de barbero se abre
11. SuperAdmin llena datos:
    - Nombre
    - Email
    - Barbería asignada
12. Sistema crea usuario en Firebase Auth
13. Sistema crea documento en Firestore (users)
14. Sistema asigna role "barber"
15. Sistema asigna barbershopId
16. Barbero puede hacer login con email y contraseña temporal
```

---

## 🚀 Instalación y Configuración

### Prerrequisitos

- Flutter SDK (>=3.0.0)
- Android Studio / VS Code
- Firebase CLI
- Cuenta de Firebase
- Git

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/tacodetripa/barber-agenda.git
cd barber-agenda
```

### Paso 2: Instalar Dependencias

```bash
flutter pub get
```

### Paso 3: Configurar Firebase

#### 3.1 Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Crea un nuevo proyecto
3. Habilita **Authentication** (Email/Password)
4. Habilita **Cloud Firestore**

#### 3.2 Agregar Apps al Proyecto

**Para Android:**
```bash
flutterfire configure
```

Selecciona tu proyecto y plataformas (Android, iOS, Web)

**Archivos generados:**
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

#### 3.3 Configurar Reglas de Firestore

En Firebase Console → Firestore → Reglas:

Copia y pega las reglas de seguridad de la sección anterior.

### Paso 4: Ejecutar la App

#### Android (Emulador o Dispositivo)

```bash
flutter run
```

#### Web

```bash
flutter run -d chrome
```

#### Generar APK

```bash
flutter build apk --release
```

El APK se generará en: `build/app/outputs/flutter-apk/app-release.apk`

#### Generar Web

```bash
flutter build web
```

Los archivos web se generarán en: `build/web/`

---

## 🧪 Pruebas

### Pruebas Unitarias

```bash
flutter test
```

### Pruebas de Integración

```bash
flutter test integration_test
```

### Cobertura de Código

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 📦 Dependencias

### Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  
  # State Management
  provider: ^6.1.1
  
  # UI
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  
  # Utilidades
  intl: ^0.18.1
  uuid: ^4.3.3
```

### Dev Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

---

## 🔧 Configuración Adicional

### Variables de Entorno

No se requieren `.env` porque Firebase se configura automáticamente con `firebase_options.dart`.

### Permisos (Android)

En `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

### Info.plist (iOS)

En `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrar barberías cercanas</string>
```

---

## 🐛 Solución de Problemas

### Error: "FirebaseOptions cannot be null"

**Solución:**
```bash
flutterfire configure
```

### Error: "MissingPluginException"

**Solución:**
```bash
flutter clean
flutter pub get
flutter run
```

### Error: "Gradle build failed"

**Solución:**
En `android/build.gradle`:
```gradle
buildscript {
    ext.kotlin_version = '1.8.0'
}
```

---

## 📱 Distribución

### APK Directo (Android)

1. Generar APK:
   ```bash
   flutter build apk --release
   ```

2. Compartir archivo `app-release.apk`

3. Usuario instala:
   - Habilitar "Fuentes desconocidas"
   - Instalar APK

### Web Hosting (Firebase)

1. Construir versión web:
   ```bash
   flutter build web
   ```

2. Deploy a Firebase:
   ```bash
   firebase deploy
   ```

3. Acceder desde: `https://barber-agenda-b3142.web.app`

---

## 🔮 Mejoras Futuras

### Corto Plazo
- [ ] Notificaciones push (recordatorios de citas)
- [ ] Recuperación de contraseña
- [ ] Fotos de perfil de barberos
- [ ] Sistema de calificaciones/reviews
- [ ] Modo oscuro

### Mediano Plazo
- [ ] Integración con Google Maps (barberías cercanas)
- [ ] Pagos integrados (Stripe/PayPal)
- [ ] Chat entre cliente y barbero
- [ ] Recordatorios automáticos por WhatsApp/SMS
- [ ] Reportes avanzados para admins

### Largo Plazo
- [ ] App Store (iOS)
- [ ] Google Play Store (Android)
- [ ] Panel web para admins
- [ ] Integración con redes sociales
- [ ] Programa de lealtad/puntos
- [ ] Multi-idioma (español/inglés)

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Para contribuir:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 👨‍💻 Autor

**[Tu Nombre]**
- Universidad: Universidad Tecnológica del Norte de Guanajuato
- Carrera: Ingeniería en Desarrollo y Gestión de Software
- Empresa: CyberSoft (Internship)
- Email: [aboytes20042610@gmail.com]
- GitHub: [@tacodetripa](https://github.com/tacodetripa)

---

## 📄 Licencia

Este proyecto es un proyecto académico desarrollado como parte del programa de Ingeniería en Desarrollo y Gestión de Software.

---

## 🙏 Agradecimientos

- Universidad Tecnológica del Norte de Guanajuato
- Profesores del programa
- Compañeros de clase
- Comunidad de Flutter
- Firebase/Google

---

## 📞 Soporte

Para reportar bugs o solicitar features:
- Abrir un [Issue](https://github.com/tacodetripa/barber-agenda/issues)
- Email: [aboytes20042610@gmail.com]
