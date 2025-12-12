# Generar icono de la app desde `AppLogo` SVG

Este proyecto incluye un archivo vectorial con el mismo diseño que el widget `AppLogo`:

- `assets/icons/app_icon.svg` — representación vectorial del `AppLogo` (1024x1024)

Para generar los iconos (Android/iOS) siguiendo el diseño del `AppLogo`:

1) Convierte el SVG a PNG (1024x1024):

   - Recomendado (Inkscape):

```powershell
# Desde la raíz del proyecto
cd "c:\Users\DavidSax\Documents\APLICACIONES\demoapp\demo"
.
\tools\convert_svg.ps1
```

   - Alternativa (ImageMagick):

```powershell
magick convert assets/icons/app_icon.svg -resize 1024x1024 assets/icons/app_icon.png
```

2) Instala la dependencia dev `flutter_launcher_icons` (si no está):

```powershell
flutter pub get
```

3) Genera los iconos para Android e iOS:

```powershell
flutter pub run flutter_launcher_icons:main
```

4) Si quieres verificar manualmente:

   - Android: revisa `android/app/src/main/res/mipmap-*` y `ic_launcher`/`ic_launcher_round`.
   - iOS: revisa `ios/Runner/Assets.xcassets/AppIcon.appiconset`.

Notas:
- Los iconos generados reemplazarán los iconos actuales del proyecto.
- Si necesitas íconos adaptativos, puedes ajustar `adaptive_icon_background` y `adaptive_icon_foreground` en `pubspec.yaml`.
- Si deseas usar directamente el widget `AppLogo` como pantalla de inicio, usa un `SplashScreen` con `AppLogo` en el `Widget` tree, pero los iconos nativos requieren un archivo PNG estático.
