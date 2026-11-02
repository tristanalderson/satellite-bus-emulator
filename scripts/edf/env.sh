#!/usr/bin/env bash
# Source this file from any working directory after bootstrap.sh has synced sources.
_edf_env_fail() { printf 'edf env: %s\n' "$*" >&2; return 1; }
_edf_env_source=${BASH_SOURCE[0]}
_edf_env_dir=$(cd -- "$(dirname -- "$_edf_env_source")" && pwd -P) || return 1
_edf_project_dir=$(cd -- "$_edf_env_dir/../.." && pwd -P) || return 1
# shellcheck disable=SC1091
source "$_edf_project_dir/config/edf-release.env" || return 1
EDF_WORKSPACE=${EDF_WORKSPACE:-"$_edf_project_dir/work/edf-workspace"}
[[ $EDF_WORKSPACE == /* ]] || EDF_WORKSPACE="$_edf_project_dir/$EDF_WORKSPACE"
EDF_WORKSPACE=$(cd -- "$EDF_WORKSPACE" 2>/dev/null && pwd -P) || { _edf_env_fail "workspace does not exist: $EDF_WORKSPACE"; return 1; }
_edf_init=$(find "$EDF_WORKSPACE" -type f -name edf-init-build-env -print -quit)
[[ -n $_edf_init ]] || { _edf_env_fail "edf-init-build-env not found under $EDF_WORKSPACE; run bootstrap.sh first."; return 1; }
EDF_BUILD_DIR=${EDF_BUILD_DIR:-"$EDF_WORKSPACE/build"}
[[ $EDF_BUILD_DIR == /* ]] || EDF_BUILD_DIR="$EDF_WORKSPACE/$EDF_BUILD_DIR"
if [[ -e $EDF_BUILD_DIR ]]; then
  [[ -f "$EDF_BUILD_DIR/conf/local.conf" && -f "$EDF_BUILD_DIR/conf/bblayers.conf" ]] || {
    _edf_env_fail "build directory exists but is not an initialized EDF build; preserving it: $EDF_BUILD_DIR"
    return 1
  }
fi
# Preserve upstream defaults; only select the documented Linux machine here.
if ! source "$_edf_init" "$EDF_BUILD_DIR"; then
  _edf_env_fail "upstream environment initialization failed: $_edf_init"
  return 1
fi
export MACHINE="$EDF_LINUX_MACHINE"

edf_verify_config() {
  local effective_machine effective_distro image_fstypes deploy_dir
  command -v bitbake >/dev/null 2>&1 || { _edf_env_fail 'bitbake is not on PATH after environment initialization.'; return 1; }
  effective_machine=$(bitbake -e "$EDF_IMAGE" | sed -n 's/^MACHINE="\([^"]*\)"$/\1/p' | tail -n 1)
  effective_distro=$(bitbake -e "$EDF_IMAGE" | sed -n 's/^DISTRO="\([^"]*\)"$/\1/p' | tail -n 1)
  image_fstypes=$(bitbake -e "$EDF_IMAGE" | sed -n 's/^IMAGE_FSTYPES="\([^"]*\)"$/\1/p' | tail -n 1)
  deploy_dir=$(bitbake -e "$EDF_IMAGE" | sed -n 's/^DEPLOY_DIR_IMAGE="\([^"]*\)"$/\1/p' | tail -n 1)
  [[ $effective_machine == "$EDF_LINUX_MACHINE" ]] || { _edf_env_fail "effective MACHINE '$effective_machine' differs from '$EDF_LINUX_MACHINE'."; return 1; }
  [[ -n $effective_distro && -n $image_fstypes && -n $deploy_dir ]] || { _edf_env_fail 'could not verify DISTRO, IMAGE_FSTYPES, or DEPLOY_DIR_IMAGE from BitBake.'; return 1; }
  printf 'MACHINE=%s\nDISTRO=%s\nIMAGE_FSTYPES=%s\nDEPLOY_DIR_IMAGE=%s\n' "$effective_machine" "$effective_distro" "$image_fstypes" "$deploy_dir"
  bitbake -p
  bitbake-layers show-layers
  bitbake-layers show-recipes "$EDF_IMAGE"
}
