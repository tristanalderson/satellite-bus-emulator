#!/usr/bin/env bash
set -Eeuo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
project=$(cd -- "$here/../.." && pwd -P)
release_file=${EDF_RELEASE_FILE:-"$project/config/edf-release.env"}
lock=${EDF_BUILDER_LOCK:-"$project/config/edf-builder-image.lock"}
[[ -r "$release_file" ]] || { printf 'run-builder: missing release contract: %s\n' "$release_file" >&2; exit 2; }
[[ -r "$lock" ]] || { printf 'run-builder: builder is not pinned; run scripts/edf/pull-builder.sh first (%s)\n' "$lock" >&2; exit 2; }
set -a
# shellcheck disable=SC1090
source "$release_file"
set +a
tag=${EDF_BUILDER_TAG:-}
digest=$(<"$lock")
[[ "$tag" && "$digest" == *@sha256:* ]] || { printf 'run-builder: invalid builder tag or digest lock\n' >&2; exit 2; }
repository=${tag%:*}
[[ "$digest" == "$repository@sha256:"* ]] || { printf 'run-builder: digest lock does not belong to configured repository %s\n' "$repository" >&2; exit 2; }
command -v docker >/dev/null 2>&1 || { printf 'run-builder: Docker is missing\n' >&2; exit 127; }
docker info >/dev/null 2>&1 || { printf 'run-builder: Docker daemon unavailable or access denied\n' >&2; exit 1; }
platform=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$digest" 2>/dev/null || true)
[[ "$platform" == linux/amd64 ]] || { printf 'run-builder: pinned linux/amd64 image is not present; run pull-builder.sh\n' >&2; exit 1; }

edf=${EDF_WORKSPACE:-"$project/work/edf"}
cache=${EDF_CACHE_DIR:-"$HOME/.cache/edf"}
downloads="$cache/downloads"; sstate="$cache/sstate"
mkdir -p -- "$edf" "$downloads" "$sstate"
for path in "$project" "$edf" "$downloads" "$sstate"; do
  [[ -w "$path" ]] || { printf 'run-builder: path is not writable: %s\n' "$path" >&2; exit 1; }
  case "$(findmnt -T "$path" -n -o FSTYPE 2>/dev/null || true)" in drvfs|9p|cifs|smb3|fuseblk) printf 'run-builder: unsupported mounted filesystem for build path: %s\n' "$path" >&2; exit 1;; esac
done

host_uid=$(id -u); host_gid=$(id -g)
# Match the host identity on bind mounts so generated files stay host-writable.
# UID/GID 1000 remains the normal image identity when the host uses it.
run_user=$host_uid:$host_gid
args=(run --rm --init --platform linux/amd64 --user "$run_user" --workdir /workspace/project
  --mount "type=bind,src=$project,dst=/workspace/project"
  --mount "type=bind,src=$edf,dst=/workspace/edf"
  --mount "type=bind,src=$downloads,dst=/workspace/cache/downloads"
  --mount "type=bind,src=$sstate,dst=/workspace/cache/sstate"
  --tmpfs "/tmp/edf-home:rw,uid=$host_uid,gid=$host_gid,mode=700" --env HOME=/tmp/edf-home --env EDF_PROJECT=/workspace/project --env EDF_WORKSPACE=/workspace/edf
  --env DL_DIR=/workspace/cache/downloads --env SSTATE_DIR=/workspace/cache/sstate)

# This runs as a non-root numeric user matching bind-mount ownership; no tree chown.
[[ -n "${EDF_GROUND_STATION_PORTS:-}" ]] && args+=(--publish "$EDF_GROUND_STATION_PORTS")
if [[ -t 0 && -t 1 ]]; then args+=(-it); fi
args+=("$digest")
if (($#)); then args+=("$@"); else args+=(bash -l); fi
exec docker "${args[@]}"
