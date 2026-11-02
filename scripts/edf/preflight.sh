#!/usr/bin/env bash
set -Eeuo pipefail

fail() { printf 'preflight: ERROR: %s\n' "$*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || fail "required command '$1' is missing"; }

[[ "$(uname -s)" == Linux ]] || fail 'run on a Linux host'
[[ "$(uname -m)" == x86_64 || "$(uname -m)" == aarch64 ]] || fail "unsupported host architecture: $(uname -m)"
need_cmd bash; need_cmd git; need_cmd docker; need_cmd df; need_cmd findmnt; need_cmd stat; need_cmd awk; need_cmd getconf
docker info >/dev/null 2>&1 || fail 'Docker daemon is unavailable or access was denied; start it and grant this user access'

project_dir=${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}
cache_dir=${EDF_CACHE_DIR:-"$HOME/.cache/edf"}
for dir in "$project_dir" "$cache_dir" "$cache_dir/downloads" "$cache_dir/sstate"; do
  mkdir -p -- "$dir" 2>/dev/null || fail "cannot create or access directory: $dir"
  [[ -w "$dir" ]] || fail "directory is not writable by $(id -un): $dir"
  fs=$(findmnt -T "$dir" -n -o FSTYPE 2>/dev/null || true)
  case "$fs" in drvfs|9p|cifs|smb3|fuseblk) fail "unsupported filesystem '$fs' for $dir; use a local Linux filesystem";; esac
  printf '%-12s %s (filesystem=%s owner=%s)\n' 'writable' "$dir" "${fs:-unknown}" "$(stat -c '%U:%G (%u:%g)' "$dir")"
done

printf 'architecture: %s\n' "$(uname -m)"
printf 'logical CPUs: %s\n' "$(getconf _NPROCESSORS_ONLN)"
awk '/MemTotal/ {printf "memory: %.1f GiB\n", $2/1048576}' /proc/meminfo
df -hP "$project_dir" "$cache_dir"
df -iP "$project_dir" "$cache_dir"
docker version --format 'Docker client/server: {{.Client.Version}} / {{.Server.Version}}' || fail 'Docker client/server query failed'
printf 'Container tool check is performed after EDF environment initialization; initial PATH is not authoritative.\n'
