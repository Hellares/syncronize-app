#!/usr/bin/env bash
# =============================================================================
# Syncronize - build-apk.sh
# Builds Flutter APK con flavor dev (beta) o prod (producción).
#
# Uso:
#   ./scripts/build-apk.sh dev     # APK dev → apunta a saas-beta.syncronize.net.pe
#   ./scripts/build-apk.sh prod    # APK prod → apunta a saas.syncronize.net.pe
#   ./scripts/build-apk.sh both    # ambos APKs (secuencial)
#
# Flags fijas:
#   --release: optimizado para distribución (NO debug).
#   --flavor + --dart-define=FLAVOR: dual-env (endpoint backend y bundleId).
#   --no-tree-shake-icons: la app guarda iconos en BD como codePoint y los
#     reconstruye en runtime, así que el tree-shaking automático no funciona.
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

build_flavor() {
  local f="$1"
  echo ""
  echo "==> [build] APK ${f} release"
  echo ""
  flutter build apk --release --flavor "${f}" --dart-define=FLAVOR="${f}" --no-tree-shake-icons

  local out="build/app/outputs/flutter-apk/app-${f}-release.apk"
  if [ -f "${out}" ]; then
    local size
    size=$(du -h "${out}" | cut -f1)
    echo ""
    echo "✓ ${f} listo: ${out} (${size})"
  fi
}

FLAVOR="${1:-}"
case "${FLAVOR}" in
  dev|prod)
    build_flavor "${FLAVOR}"
    ;;
  both)
    build_flavor dev
    build_flavor prod
    ;;
  *)
    echo "Uso: $0 {dev|prod|both}"
    exit 1
    ;;
esac

echo ""
echo "==> [done] Build finalizado"
