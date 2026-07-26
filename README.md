# aspire_app

App Flutter de una plataforma de mentoría con IA. El proyecto está en sus
fundaciones: hoy hay una pantalla de login y la integración del cliente de
Supabase.

## Arranque

Flutter está fijado en **3.44.2** vía FVM. En un clon nuevo:

```bash
fvm install
fvm flutter pub get
fvm flutter run -d chrome
```

`fvm install` no es opcional: `.fvm/` está en `.gitignore`, así que sin él el
IDE no resuelve el SDK.

**Guía completa en [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)**: requisitos,
secuencia verificada, configuración por entorno con `--dart-define` y matriz de
problemas frecuentes en Windows.

## Arquitectura

Clean architecture (`presentation → domain ← data`) y atomic design en
`lib/presentation/widgets/`. Las reglas están en [CLAUDE.md](CLAUDE.md).
