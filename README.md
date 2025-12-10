# Control de Acceso - Universidad del Pacífico (Flutter + Firebase + Cloudinary)

Proyecto de ejemplo para controlar entradas y salidas de usuarios usando Flutter, Firestore y Cloudinary.

Pasos rápidos para ejecutar:

1. Coloca `google-services.json` en `android/app/` y `GoogleService-Info.plist` en `ios/Runner/`.
2. Crea un archivo `.env` en la raíz (no lo comitees) con las variables necesarias. Usa `.env.example` como guía.
3. Instala dependencias:

```bash
flutter pub get
```

4. Ejecuta la app:

```bash
flutter run
```

Variables de entorno:
- Crea un archivo `.env` en la raíz con las siguientes variables (ejemplo en `.env.example`) si tu app usa servicios externos para subir archivos.

Android & iOS:
- Asegúrate de que `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) estén en los paths correctos.
- Para Android, en `android/` configura `minSdk >= 21` si usas paquetes que lo requieren.
- En iOS, añade `NSCameraUsageDescription` en `Info.plist`.

Firestore:
- Para prototipo, puedes dejar reglas abiertas, pero para producción configura reglas que limiten solo personal autorizado a escribir.

Permisos y configuración adicional:
- Android: agrega permisos en `android/app/src/main/AndroidManifest.xml` si no están ya: `android.permission.CAMERA`, `android.permission.INTERNET`.
- iOS: agrega en `ios/Runner/Info.plist` la key `NSCameraUsageDescription` (texto para el usuario). No es necesario `NSPhotoLibraryAddUsageDescription` ya que la app ya no guarda/selecciona fotos desde la galería.

Registro:
- La pantalla de registro ahora permite registrar:
	- Nombre completo (obligatorio)
	- Cédula (obligatorio)
	- Código del carnet (barcode) (obligatorio)
	- Programa académico (obligatorio)
# demo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
