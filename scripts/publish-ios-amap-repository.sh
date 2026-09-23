#!/usr/bin/env bash
# Publish a generated source package after its binary Release assets are available.
set -euo pipefail
if [[ "$#" != 3 ]]; then
  echo "Usage: bash scripts/publish-ios-amap-repository.sh <generated-directory> <owner/repository> <version>" >&2
  exit 2
fi
package_dir="$(cd "$1" && pwd)"
repository="$2"
version="$3"
[[ "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]]
test -s "$package_dir/Package.swift"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

existing_tag="$(git ls-remote --tags "https://github.com/$repository.git" "refs/tags/v$version")"
if [[ -n "$existing_tag" ]]; then
  echo "Tag v$version already exists in $repository; refusing to replace it" >&2
  exit 1
fi
# Resolve the actual remote binary targets before publishing a usable package tag.
swift package --package-path "$package_dir" --scratch-path "$work/build" resolve
gh repo clone "$repository" "$work/repository"
cd "$work/repository"
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  branch="$(git branch --show-current)"
else
  branch=main
  git checkout --orphan "$branch"
fi
for item in Package.swift README.md LICENSE NOTICE vendor.json .gitignore Sources; do
  test -e "$package_dir/$item"
  rm -rf -- "$item"
  cp -R "$package_dir/$item" "$item"
done
git add Package.swift README.md LICENSE NOTICE vendor.json .gitignore Sources
if ! git diff --cached --quiet; then
  git -c user.name='github-actions[bot]' -c user.email='41898282+github-actions[bot]@users.noreply.github.com' \
    commit -m "Release DiminaMapAMap $version"
fi
git tag "v$version"
git push --atomic origin "HEAD:refs/heads/$branch" "refs/tags/v$version"
gh release create "v$version" --repo "$repository" --verify-tag \
  --title "DiminaMapAMap $version" --notes "Swift Package for Dimina $version. Binary dependencies are verified by SwiftPM checksums."
