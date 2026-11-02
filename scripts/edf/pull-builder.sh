#!/usr/bin/env bash
set -Eeuo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
project=$(cd -- "$here/../.." && pwd -P)
release_file=${EDF_RELEASE_FILE:-"$project/config/edf-release.env"}
[[ -r "$release_file" ]] || { printf 'pull-builder: missing release contract: %s\n' "$release_file" >&2; exit 2; }
# This config is a trusted, project-maintained shell assignment file.
set -a
# shellcheck disable=SC1090
source "$release_file"
set +a
image=${EDF_BUILDER_TAG:-}
[[ -n "$image" ]] || { printf 'pull-builder: EDF_BUILDER_TAG is unset in %s\n' "$release_file" >&2; exit 2; }
command -v docker >/dev/null 2>&1 || { printf 'pull-builder: Docker is missing\n' >&2; exit 127; }
docker info >/dev/null 2>&1 || { printf 'pull-builder: Docker daemon unavailable or access denied\n' >&2; exit 1; }

printf 'Pulling explicitly selected builder %s\n' "$image"
docker pull --platform linux/amd64 "$image"
platform=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$image")
[[ "$platform" == linux/amd64 ]] || { printf 'pull-builder: expected linux/amd64, found %s\n' "$platform" >&2; exit 1; }
digest=$(docker image inspect --format '{{index .RepoDigests 0}}' "$image")
[[ "$digest" == *@sha256:* ]] || { printf 'pull-builder: image has no registry digest; refusing mutable tag\n' >&2; exit 1; }
repository=${image%:*}
[[ "$digest" == "$repository@sha256:"* ]] || { printf 'pull-builder: returned digest does not match repository %s: %s\n' "$repository" "$digest" >&2; exit 1; }
lock="$project/config/edf-builder-image.lock"
mkdir -p -- "$(dirname -- "$lock")"
if [[ -e "$lock" ]] && [[ "$(<"$lock")" != "$digest" ]]; then
  printf 'pull-builder: existing digest differs; preserving %s\n' "$lock" >&2
  exit 1
fi
tmp=$(mktemp "${lock}.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
printf '%s\n' "$digest" > "$tmp"
mv -f -- "$tmp" "$lock"
trap - EXIT
printf 'Builder digest recorded: %s\nLock file: %s\n' "$digest" "$lock"
