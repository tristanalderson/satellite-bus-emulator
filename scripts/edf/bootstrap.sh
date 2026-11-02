#!/usr/bin/env bash
# Bootstrap a separate EDF checkout. Run in the selected EDF builder container.
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  bootstrap.sh sync [workspace]
  bootstrap.sh replay [workspace] [resolved-manifest.xml]

EDF_REPO_VERSION must contain the exact output of `repo --version`, and `repo`
with that version must already be installed. No repo tool is installed or updated.
EOF
}
fail() { printf 'edf bootstrap: %s\n' "$*" >&2; exit 2; }

mode=${1:-}
case "$mode" in sync|replay) shift ;; *) usage >&2; exit 2 ;; esac
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
project_dir=$(cd -- "$script_dir/../.." && pwd -P)
# shellcheck disable=SC1091
source "$project_dir/config/edf-release.env"
workspace=${1:-${EDF_WORKSPACE:-"$project_dir/work/edf-workspace"}}
workspace=$(mkdir -p -- "$(dirname -- "$workspace")" && cd -- "$(dirname -- "$workspace")" && printf '%s/%s\n' "$PWD" "$(basename -- "$workspace")")
resolved_manifest=${2:-"$project_dir/manifests/edf-resolved.xml"}
if [[ $resolved_manifest != /* ]]; then resolved_manifest="$PWD/$resolved_manifest"; fi

[[ -n ${EDF_REPO_VERSION:-} ]] || fail 'set EDF_REPO_VERSION to an authoritative exact `repo --version` string; no pin is recorded in the release contract.'
command -v repo >/dev/null 2>&1 || fail 'repo is unavailable; install the approved pinned version in the builder environment.'
actual_repo_version=$(repo --version 2>&1) || fail 'could not read repo version.'
[[ "$actual_repo_version" == "$EDF_REPO_VERSION" ]] || fail "repo version mismatch (expected '$EDF_REPO_VERSION', got '$actual_repo_version')."
command -v git >/dev/null 2>&1 || fail 'git is required.'

if [[ -e "$workspace/.repo" || -e "$workspace/.git" ]]; then
  fail "workspace already contains source metadata; preserving it at $workspace. Choose a new empty path or inspect it manually."
fi
if [[ -e "$workspace" ]] && [[ -n $(find "$workspace" -mindepth 1 -maxdepth 1 -print -quit) ]]; then
  fail "workspace is not empty; preserving it at $workspace. Choose a new empty path."
fi
mkdir -p -- "$workspace"
cd -- "$workspace"

case "$mode" in
  sync)
    repo init -u "$EDF_MANIFEST_URL" -b "$EDF_MANIFEST_REF" -m "$EDF_MANIFEST_FILE"
    repo sync
    mkdir -p -- "$(dirname -- "$resolved_manifest")"
    repo manifest -r -o "$resolved_manifest"
    printf 'Resolved manifest exported to %s\n' "$resolved_manifest"
    ;;
  replay)
    [[ -r "$resolved_manifest" ]] || fail "resolved manifest is missing or unreadable: $resolved_manifest"
    # A local manifest repository lets repo consume the exact project revisions
    # in the lock file without modifying or guessing the upstream release tag.
    manifest_hash=$(git hash-object "$resolved_manifest")
    manifest_repo="$project_dir/work/edf-manifest-replay-$manifest_hash"
    if [[ ! -e "$manifest_repo" ]]; then
      mkdir -p -- "$manifest_repo"
      git -C "$manifest_repo" init -q
      git -C "$manifest_repo" symbolic-ref HEAD refs/heads/master
      git -C "$manifest_repo" config user.name 'EDF manifest replay'
      git -C "$manifest_repo" config user.email 'edf-manifest-replay@localhost'
      cp -- "$resolved_manifest" "$manifest_repo/edf-resolved.xml"
      git -C "$manifest_repo" add edf-resolved.xml
      git -C "$manifest_repo" commit -qm 'Replay resolved EDF manifest'
    elif [[ ! -f "$manifest_repo/edf-resolved.xml" ]] || [[ $(git -C "$manifest_repo" hash-object edf-resolved.xml) != "$manifest_hash" ]]; then
      fail "saved local manifest repository is inconsistent; preserving it at $manifest_repo. Inspect manually."
    fi
    repo init -u "file://$manifest_repo" -m edf-resolved.xml
    repo sync
    ;;
esac
printf 'Workspace: %s\nRepo: %s\n' "$workspace" "$actual_repo_version"
