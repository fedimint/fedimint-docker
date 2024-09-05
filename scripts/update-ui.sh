#!/usr/bin/env bash

version=$1

if [ -z "$version" ] || ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage: $0 X.X.X (e.g., 1.2.3)"
  exit 1
fi

find configurations -name docker-compose.yaml | while read -r file; do
  sed -i '' "s|image: fedimintui/guardian-ui:[0-9.]*|image: fedimintui/guardian-ui:v$version|g" "$file"
  sed -i '' "s|image: fedimintui/gateway-ui:[0-9.]*|image: fedimintui/gateway-ui:v$version|g" "$file"
  echo "Updated Guardian and Gateway UI version to $version in $file"
done
