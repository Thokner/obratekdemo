# Obratek 0.0.004 — código Flutter para GitHub y Codemagic

Este repositorio contiene **solo el frontend Flutter**: aplicación web, Android e iPhone.
Es el proyecto de demostración `DEMO_MODE=true`, sin servidor ni datos reales.

## Cómo subirlo a GitHub

1. Descomprime el ZIP.
2. Crea un repositorio **privado** llamado `obratek-app` en GitHub.
3. Sube **los archivos y carpetas que están dentro** de la carpeta descomprimida a la raíz del repositorio.
4. Confirma que `pubspec.yaml`, `lib/` y `codemagic.yaml` estén en la **raíz**, no dentro de otro nivel de carpetas.
5. No subas tu carpeta antigua con `build/`, `.dart_tool/`, `.gradle/`, `.env`, `backend/` ni credenciales.

## Compilar iPhone en Codemagic

1. Conecta a Codemagic tu repositorio privado de GitHub.
2. Selecciona la configuración **codemagic.yaml**.
3. Ejecuta el flujo `ios-check` para verificar que compile en macOS.
4. El flujo genera la carpeta iOS en Codemagic porque el proyecto original se creó en Windows.
5. La salida sin firma (`.app`) **no se puede instalar en un iPhone**. Para TestFlight hará falta configurar la cuenta Apple Developer, un identificador de app, certificados y firma de distribución. No se incluyen esas credenciales aquí.

## Ejecutar en tu PC

```powershell
flutter pub get
flutter run -d chrome --dart-define=DEMO_MODE=true
```

Para crear nuevamente un APK de prueba en Windows:

```powershell
flutter build apk --release --dart-define=DEMO_MODE=true
```

Versión Flutter del proyecto: `0.0.4+4` (Obratek 0.0.004).

**Nota:** Se corrigió una prueba de ejemplo generada automáticamente que hacía referencia a clases ajenas a Obratek. La compilación de iOS no se ha verificado aquí; el primer flujo de Codemagic sirve precisamente para comprobarla.
