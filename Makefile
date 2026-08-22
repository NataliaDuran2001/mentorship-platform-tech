.PHONY: help install get run run-chrome run-windows analyze test test-file format clean build-web supabase-start supabase-stop supabase-status supabase-reset

help:
	@echo "Targets disponibles:"
	@echo "  install         - fvm install (version pinneada en .fvmrc)"
	@echo "  get             - fvm flutter pub get"
	@echo "  run             - fvm flutter run"
	@echo "  run-chrome      - fvm flutter run -d chrome"
	@echo "  run-windows     - fvm flutter run -d windows"
	@echo "  analyze         - fvm flutter analyze --fatal-infos"
	@echo "  test            - fvm flutter test (todos los tests)"
	@echo "  test-file f=... - fvm flutter test para un archivo puntual (ej: make test-file f=test/presentation/roadmap_test.dart)"
	@echo "  format          - fvm dart format lib test"
	@echo "  clean           - fvm flutter clean"
	@echo "  build-web       - fvm flutter build web"
	@echo "  supabase-start  - supabase start (stack local)"
	@echo "  supabase-stop   - supabase stop"
	@echo "  supabase-status - supabase status"
	@echo "  supabase-reset  - supabase db reset (re-aplica migrations + seeds)"

install:
	fvm install

get:
	fvm flutter pub get

run:
	fvm flutter run -d chrome

run-chrome:
	fvm flutter run -d chrome

run-windows:
	fvm flutter run -d windows

analyze:
	fvm flutter analyze --fatal-infos

test:
	fvm flutter test

test-file:
	fvm flutter test $(f)

format:
	fvm dart format lib test

clean:
	fvm flutter clean

build-web:
	fvm flutter build web

supabase-start:
	supabase start

supabase-stop:
	supabase stop

supabase-status:
	supabase status

supabase-reset:
	supabase db reset
