# KV260 EDF migration action plan

Started 2026-11-02. This is a working plan for the EDF migration. Some scripts are in place, but the image, SDK, and board still need testing.

I want to move the existing Linux and F Prime application from the 2024.2 Yocto configuration to a reproducible EDF release, without losing the setup I already have. RTL, R5 firmware, PCB design, and an F Prime upgrade can come later.

## Agent coordination

The planner owns sequencing, integration, shared files, review, and acceptance. Future implementation agents use the smaller, faster `gpt-6-luna` model with narrowly scoped tasks, as requested by the user. Start them with explicit briefs and file ownership rather than full conversation history. Use at most three workers concurrently; run only one heavy image build at a time.

The three initial read-only planning reviews are complete. No implementation task below is marked complete by those reviews.

Every worker must inspect current Git status and applicable repository instructions before editing. Preserve unrelated user changes. Report changed files, exact checks and results, unresolved dependencies, and the next handoff. Never report a hardware test as passed from software evidence. Do not edit another worker's files; send integration requests to the planner. The planner creates a migration branch from the actual current checkout after preserving any user changes; baseline at assessment was b63a5e5.

## Release contract

The EDF worker owns `config/edf-release.env`. Other workers consume it and request changes through that owner.

```sh
EDF_MANIFEST_URL=https://github.com/Xilinx/yocto-manifests.git
EDF_MANIFEST_REF=refs/tags/amd-edf-rel-v26.06.1
EDF_MANIFEST_FILE=default-edf.xml
EDF_LINUX_MACHINE=amd-cortexa53-mali-common
EDF_IMAGE=edf-linux-disk-image-kria
EDF_BOOT_MACHINE=k26-smk-kv-sdt
EDF_BOOT_RECIPE=kria-qspi
EDF_BUILDER_TAG=xilinx/edf:ubuntu2204-26.06
FPRIME_REVISION=8a62e455a90b6d4f498c332d45d65a2a819988d8
```

Verify the manifest tag and contents during execution. Record the manifest commit, resolved layer revisions, repo-tool version, and builder digest after retrieval. No SHA or digest should be invented. The tag is the starting selection; a resolved manifest and container digest establish the reproducible configuration. Keep old configuration and SDK separate.

AMD's current instructions document the manifest selection. Its Kria-specific image guidance distinguishes Linux disk-image targets from the board boot-firmware machine. Some OpenAMP documentation differs in scope; defer that issue because this milestone is Linux-only.

Sources: [EDF build instructions](https://edf.docs.amd.com/en/latest/osdev/operating-system-integration-and-development.html), [Kria machine and image specifications](https://edf.docs.amd.com/en/latest/ref/common-specifications.html), [EDF build container](https://edf.docs.amd.com/en/latest/osdev/build-edf-yocto-with-the-edf-build-container.html).

## Baseline and host gate

Planner tasks before implementation builds:

1. Record source commit and working-tree status; create an isolated migration branch. Preserve the current SD card, image, SDK, binary, and matching dictionary if available. Record unavailable artifacts explicitly.
2. Establish one authoritative Linux build checkout. Record its source commit before each build.
3. Inventory the Linux build host and verify Docker availability. Hardware tool installation is not a prerequisite for the stock EDF image build.
4. Record board revision, serial connection, current boot firmware, and available SD media when hardware becomes accessible. Do not guess a disk device or board address.

Gate G0 passes when the baseline is recorded and a usable Linux build host, writable Linux filesystem, container runtime, and resource budget are verified. Record measured memory, disk, and inodes and choose build parallelism accordingly.

## Worker A host and container

Dispatch brief: Implement the host preparation and container launcher only. Preserve the legacy Dockerfile and launcher. Coordinate release configuration with Worker B. Do not install hardware tools or alter board storage.

Owned files: `scripts/edf/preflight.sh`, `scripts/edf/pull-builder.sh`, and `scripts/edf/run-builder.sh`.

Tasks:

1. Implement Linux preflight for architecture, Bash, Git, container daemon, writable workspace/cache, filesystem, ownership, resources, and required container tools. Use a suitable local Linux filesystem for the build.
3. Pull the selected builder in a separate explicit step. Verify linux/amd64 architecture, record its digest, and use that digest subsequently. Do not silently fall back to latest.
4. Provide stable project, EDF workspace, download-cache, and sstate-cache mounts. Support interactive use and noninteractive command execution with correct exit status and signals. Allocate TTY only when available. Personal editor mounts are excluded; ground-station ports are opt-in.
5. Handle the image's default UID/GID 1000 and differing host IDs deliberately, with a writable HOME and non-root build user. Avoid broad recursive ownership changes.

Acceptance: syntax checks and ShellCheck where available; actionable errors for missing Docker/daemon and invalid paths; paths containing spaces work; intentional nonzero child exit is propagated; generated files persist and remain host-writable. BitBake availability is checked after environment initialization, not assumed on the container's initial PATH.

Handoff: exact launcher invocation, image digest, mount map, host resource report, and results to planner and Worker B.

## Worker B EDF bootstrap and image

Dispatch brief: Implement a separate pinned EDF source/build workflow. Preserve `build-k26/conf` and legacy scripts. Own the shared release contract. Do not carry forward old configuration overrides without evidence.

Owned files: `config/edf-release.env`, `scripts/edf/bootstrap.sh`, `scripts/edf/env.sh`, and `manifests/edf-resolved.xml` once sources are synchronized. Request ignore-file and README edits from the planner.

Tasks:

1. Initialize a distinct ignored EDF workspace using the release contract and a pinned repo tool. Reject incompatible existing metadata; preserve local edits and failed workspaces.
2. Synchronize sources and export a resolved manifest. Implement and document replay of that manifest in a clean workspace; exporting a lock without consuming it is insufficient.
3. Wrap `edf-init-build-env` in a sourced, directory-independent script. Preserve upstream defaults and create a new build directory. Do not copy legacy absolute BBLAYERS, DISTRO=poky, package removals, or boot-file removals.
4. Verify effective machine, distribution, layers, image formats, and output paths. Run parse, recipe discovery, fetch, and image build in that order.

Initial source setup inside the selected workspace:

```sh
repo init -u https://github.com/Xilinx/yocto-manifests.git \
  -b refs/tags/amd-edf-rel-v26.06.1 -m default-edf.xml
repo sync
repo manifest -r -o /absolute/project/path/manifests/edf-resolved.xml
```

After initializing the EDF build environment:

```sh
export MACHINE=amd-cortexa53-mali-common
bitbake -p
bitbake-layers show-layers
bitbake-layers show-recipes edf-linux-disk-image-kria
bitbake -e edf-linux-disk-image-kria
bitbake edf-linux-disk-image-kria --runall=fetch
bitbake edf-linux-disk-image-kria
```

Capture relevant configuration rather than publishing environment dumps containing credentials. Inspect deployed filenames rather than assuming legacy WIC paths. Archive image checksums, package manifest, source revisions, configuration, and build log.

Gate G1: bootstrap is repeatable, resolved revisions replay correctly, and BitBake parses and finds the image. Gate G2: fetch and image build pass and output provenance is recorded. Neither gate establishes board boot success.

## Worker C F prime and SDK integration

Dispatch brief: Retain the recorded F Prime gitlink and current topology. Fix environment and SDK integration. Keep native and cross-build caches separate. Do not upgrade framework or redesign communications.

Owned files: `scripts/setup-fprime.sh`, a project Python constraints file, `scripts/install-sdk.sh`, `scripts/fprime-cross-env.sh`, and `satellite-bus/cmake/toolchain/kv260-yocto.cmake`.

Tasks:

1. Initialize recursive submodules at the recorded commit, never with --remote. Create a dedicated virtual environment using existing requirements. Validate and pin compatible host tooling.
2. Coordinate matching SDK selection with Worker B. Verify the selected EDF SDK recipe and its target sysroot against the built image before choosing the build command. Do not reuse the 2024.2 SDK by default.
3. Require an explicit installer/destination or unambiguous discovery. Fail on zero or multiple candidates. Preserve legacy SDK installations and record installer checksum.
4. Resolve paths from BASH_SOURCE and handle source-script failures with return. Replace the hardcoded environment filename; verify sysroot, compiler, and virtual environment before success.
5. Use the SDK-provided CMake integration where available. Preserve compiler flags and sysroot configuration; do not treat a CC value containing arguments as one executable path. Retain FPRIME_PLATFORM=Linux and reject host-compiler fallback.
6. Build a small C++ smoke program and inspect its architecture and loader requirements. Rebuild SatelliteDeployment in a clean cross-build directory. Archive its binary and generated dictionary together.

Acceptance: exact framework revision restored; fprime-util and fprime-gds run; missing/ambiguous SDK errors are clear; environment works from unrelated directories; verbose builds use the intended SDK; ELF and rootfs loader/library compatibility are checked. On-target smoke-program execution and F Prime communications remain hardware gates.

## Planner integration and board validation

Planner owns `.gitignore`, `.gitattributes`, README updates, migration records, and final cross-file review. Enforce LF for shell scripts and appropriate executable modes. The current install-sdk.sh is mode 100644 despite direct execution in README. Ignore generated workspaces, SDKs, logs, and build artifacts while retaining release metadata.

Begin official prebuilt-image boot checks as soon as the host and board are available, independently of source-build implementation. Record image identity/checksum and serial output. Inspect installed boot firmware and release requirements first. Firmware changes, if necessary, must use the verified board-specific artifact and documented recovery path; never flash from an inferred device name.

AMD documents A/B firmware updates and compatibility differences across releases. Preserve both image and firmware identity in rollback records. An old SD card alone does not restore changed QSPI state. Source: [Kria boot firmware guidance](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/1641152513/Kria+SOMs+Starter+Kits).

Gate G3 requires the source-built EDF image on the actual KV260:

1. Serial console and networking work on three cold boots.
2. SDK smoke executable runs without loader or symbol errors.
3. SatelliteDeployment starts with its matching GDS dictionary and periodic telemetry advances.
4. A harmless command selected from that dictionary produces the expected response or event.
5. Application stop/restart and GDS disconnect/reconnect behavior are recorded. Compare with the existing baseline before declaring automatic reconnect a new requirement.
6. Record image checksum, boot firmware, binary/dictionary identity, commands, logs, and pass/fail results in a validation record.

If board access is unavailable, stop at the last verified gate and report hardware validation pending. Do not substitute simulated or build-only results.

## Execution order and completion

| Wave | Work | Dependency |
| --- | --- | --- |
| 0 | Planner baseline and host selection | None |
| 1 | A preflight/launcher, B release/bootstrap, C framework setup | Agreed release contract; files disjoint |
| 2 | B sync/parse/fetch/image; C SDK integration once SDK available | G0 and usable launcher |
| 3 | Planner runtime integration and hardware validation | G2, rebuilt F Prime, board access |
| 4 | Application Yocto packaging and reproducibility check | G3 |

Compatibility milestone completes at G3. Reproducible-release milestone additionally requires a project-owned Yocto layer that builds the application from pinned source, installs runtime configuration and a startup service, and exports the dictionary from the same build. Host Python tooling stays out of the target image. Validate boot startup and service restart. Assign this as a separate small worker task after compatibility is proven.

On failure, preserve the first relevant error and logs, classify the failure as host, source, recipe, SDK, boot, or runtime, and change one variable at a time. After two focused attempts on the same blocker, the planner reassesses the approach instead of adding speculative overrides. Do not silently change release, discard workspaces, or claim the migration complete to bypass a blocker.

## Status checklist

- [x] Repository and official guidance assessed.
- [x] Three specialist planning reviews incorporated.
- [x] Future workers assigned smaller, faster model preference.
- [ ] G0 baseline and build host verified.
- [ ] Implementation workers dispatched with the briefs above.
- [ ] G1 pinned bootstrap and parsing verified.
- [ ] G2 source-built image and matching SDK produced.
- [ ] G3 board boots and existing F Prime behavior verified.
- [ ] Application packaged and clean reproducible release validated.
