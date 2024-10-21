#!/usr/bin/env bash

version=$1

if [ -z "$version" ] || ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage: $0 X.X.X (e.g., 1.2.3)"
  exit 1
fi

find configurations -name docker-compose.yaml | while read -r file; do
  sed -i '' "s|image: fedimint/gatewayd:v[0-9.]*|image: fedimint/gatewayd:v$version|g" "$file"
  sed -i '' "s|image: fedimint/fedimintd:v[0-9.]*|image: fedimint/fedimintd:v$version|g" "$file"
  echo "Updated Fedimintd and Gatewayd version to $version in $file"
done

# Update README.md
sed -i '' "s|Current version of Fedimintd and Gatewayd: \`v[0-9.]*\`|Current version of Fedimintd and Gatewayd: \`v$version\`|g" README.md
echo "Updated version in README.md to $version"
