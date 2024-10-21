#!/usr/bin/env bash

version=$1

if [ -z "$version" ] || ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage: $0 X.X.X (e.g., 1.2.3)"
  exit 1
fi

# Update docker-compose.yaml files
find configurations -name docker-compose.yaml | while read -r file; do
  sed -i '' "s|image: fedimintui/fedimint-ui:[0-9.]*|image: fedimintui/fedimint-ui:$version|g" "$file"
  sed -i '' "s|image: fedimintui/fedimint-ui:[0-9.]*|image: fedimintui/fedimint-ui:$version|g" "$file"
  echo "Updated Guardian and Gateway UI version to $version in $file"
done

# Update README.md
sed -i '' "s|Current version of UI: \`v[0-9.]*\`|Current version of UI: \`v$version\`|g" README.md
echo "Updated version in README.md to $version"
