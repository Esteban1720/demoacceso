# Control de Acceso - Universidad del Pacífico ✅

**App de control de accesos para campus universitario**

Una aplicación Flutter que permite registrar usuarios, identificar personas mediante el escaneo del código del carnet (QR/barcode) y registrar entradas y salidas (accesos) en Firestore.

---

## 📋 Tabla de contenido

- [Descripción](#descripción)
- [Funcionalidades](#funcionalidades)
- [Tecnologías utilizadas](#tecnologías-utilizadas)
- [Estructura clave del proyecto](#estructura-clave-del-proyecto)
- [Instalación y configuración](#instalación-y-configuración)
- [Variables de entorno](#variables-de-entorno)
- [Ejecución y pruebas](#ejecución-y-pruebas)
- [Notas de despliegue y seguridad](#notas-de-despliegue-y-seguridad)
- [Contribuciones](#contribuciones)

---

## 🔎 Descripción

La aplicación permite gestionar el acceso a instalaciones:
- Registrar usuarios (Estudiante, Profesor, Administrador, Servicio general).
- Identificar usuarios mediante el escaneo del código del carnet (barcode/QR).
- Registrar entradas y salidas y consultar el historial de accesos.
- Arquitectura orientada a Flutter + Firebase Firestore como backend.

> La app incluye puntos para soportar subida de imágenes a servicios externos si se configuran variables de entorno, pero **el README no entra en detalle de servicios específicos**.

---

## ✨ Funcionalidades principales

- Registro de usuarios con validaciones por tipo (Estudiante, Profesor, etc.).
- Escaneo de códigos con cámara (soporte por `barcode_scan2` / `mobile_scanner`).
- Registro de accesos: crear entrada, registrar salida, consultar historial.
- Interacciones con Firestore a través de `lib/services/firestore_service.dart`.
- Tests de widgets para pantallas clave (ej. `RegistroScreen`).

---

## 🧰 Tecnologías utilizadas

Basado en `pubspec.yaml` — versiones actuales (ejemplos):

- Flutter SDK: ^3.9.2
- firebase_core: ^2.10.0
- cloud_firestore: ^4.5.0
- barcode_scan2: ^4.2.0
- mobile_scanner: ^4.0.0
- image_picker: ^1.1.0
- http: ^1.1.0
- flutter_riverpod: ^2.1.0
- flutter_dotenv: ^5.0.2
- uuid: ^4.2.0
- cupertino_icons: ^1.0.8

Dev dependencies:
- flutter_test
- flutter_lints: ^5.0.0
- flutter_launcher_icons: ^0.10.0

Plataformas soportadas: Android, iOS, Web, Windows, macOS, Linux.

---

## 🗂️ Estructura clave del proyecto

- `lib/main.dart` — Inicialización (dotenv, Firebase) y rutas.
- `lib/services/firestore_service.dart` — Acceso a Firestore (colecciones: `Usuario`, `accesos`).
- `lib/services/cloudinary_service.dart` — Ejemplo de servicio de subida HTTP desde `.env` (opcional).
- `lib/screens/registro_screen.dart` — Formulario de registro y lógica de UI.
- `lib/screens/scan_screen.dart`, `historial_screen.dart` — Escaneo y historial.
- `test/` — Tests de widgets (`registro_screen_test.dart`).

---

## ⚙️ Instalación y configuración

Requisitos:
- Flutter compatible (ver `environment` en `pubspec.yaml`).
- Tener configurado Firebase para Android/iOS (archivos de configuración).

Pasos:
1. Clona el repositorio.
2. Copia los archivos de configuración de Firebase:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. Crea un archivo `.env` en la raíz (no subirlo al repo). Ver sección de variables de entorno.
4. Instala dependencias:

```bash
flutter pub get
```

5. Ejecuta la app en un emulador o dispositivo:

```bash
flutter run
```

---

## 🔑 Variables de entorno

Ejemplo de variables que pueden aparecer en `.env` (el proyecto incluye un `.env` de ejemplo en desarrollo):

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- (Opcional) `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_UPLOAD_PRESET` — solo si se utiliza un servicio externo para subir imágenes

> Asegúrate de **no** subir el `.env` ni secretos al control de versiones. Usa variables de entorno en CI/CD para producción.

---

## ▶️ Ejecución y pruebas

- Ejecutar la app:

```bash
flutter run
```

- Construir APK (Android):

```bash
flutter build apk --release
```

- Ejecutar tests:

```bash
flutter test
```

---

## 🔒 Notas de seguridad y despliegue

- En desarrollo las reglas de Firestore pueden ser más permisivas; **en producción** aplica reglas estrictas que limiten lectura/escritura.
- No comites claves privadas ni `.env` al repositorio.
- Revisa `minSdkVersion` en Android si alguna dependencia lo requiere.

---

## 🤝 Contribuciones

Si deseas contribuir:
1. Crea una rama feature (`git checkout -b feat/mi-cambio`).
2. Haz commits claros.
3. Abre un Merge Request / Pull Request describiendo el cambio.

---

## 📄 Licencia y contacto

Esteban David Ruiz Caicedo
correo:dr0238335@gmail.com
contacto:3207012503


