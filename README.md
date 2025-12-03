# Control de Acceso - Universidad del Pacífico (Flutter + Firebase + Cloudinary)

Proyecto de ejemplo para controlar entradas y salidas de estudiantes usando Flutter, Firestore y Cloudinary.

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

Cloudinary:
- Para probar sin backend, crea un `upload_preset` sin firma (unsigned) en Cloudinary y colócalo en `.env`.
- Para producción, implementa una Cloud Function que devuelva el `signature` y usa `signed` uploads.

Variables de entorno:
- Crea un archivo `.env` en la raíz con las siguientes variables (ejemplo en `.env.example`):
	- CLOUDINARY_CLOUD_NAME=df963uwem
	- CLOUDINARY_UPLOAD_PRESET=mi_upload_preset_unauthorized

Android & iOS:
- Asegúrate de que `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) estén en los paths correctos.
- Para Android, en `android/` configura `minSdk >= 21` si usas paquetes que lo requieren.
- En iOS, añade `NSCameraUsageDescription` en `Info.plist`.

Firestore:
- Para prototipo, puedes dejar reglas abiertas, pero para producción configura reglas que limiten solo personal autorizado a escribir.

Permisos y configuración adicional:
- Android: agrega permisos en `android/app/src/main/AndroidManifest.xml` si no están ya: `android.permission.CAMERA`, `android.permission.INTERNET`.
- iOS: agrega en `ios/Runner/Info.plist` las keys `NSCameraUsageDescription` (texto para el usuario) y `NSPhotoLibraryAddUsageDescription`.

Cloudinary:
- Crea un `upload_preset` unsigned en Cloudinary para pruebas. Es la forma más sencilla de subir desde la app sin exponer secret.
- Para producción, usa Cloud Functions o tu backend para firmar uploads (signed uploads), de modo que no almacenes `api_secret` en el cliente.
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
