#!/usr/bin/env sh
# Gera habitquest_entrega.zip contendo EXCLUSIVAMENTE a pasta lib/ e o pubspec.yaml.
# Uso (na raiz do projeto):  sh scripts/gerar_zip.sh
set -e
cd "$(dirname "$0")/.."
rm -f habitquest_entrega.zip
zip -r habitquest_entrega.zip lib pubspec.yaml
echo "ZIP gerado: habitquest_entrega.zip"
