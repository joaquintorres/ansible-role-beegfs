#!/bin/bash
# T05 spike: build kmod-beegfs with https://gitlab.com/ccad/beegfs-kmod inside an
# EL container and report findings as GitHub annotations (readable via the
# public check-runs API) and in the job summary.
# Usage: spike.sh <beegfs_version>   e.g. 8.4, 7.4.6
set -euo pipefail

BEEGFS_VERSION=$1
EL=$(rpm -E %rhel)
WORK=$(mktemp -d)
OUT=${GITHUB_WORKSPACE:-$PWD}/spike-out
mkdir -p "$OUT"

annotate() {  # annotate <notice|warning|error> <title>  (message on stdin)
  local m
  m=$(cat)
  m=${m//'%'/'%25'}; m=${m//$'\r'/}; m=${m//$'\n'/'%0A'}
  echo "::$1 title=EL$EL BeeGFS $BEEGFS_VERSION: $2::$m"
}
summary() { echo "$*" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"; }

# --- build dependencies ------------------------------------------------------
dnf -y -q install dnf-plugins-core
if [ "$EL" = 8 ]; then dnf config-manager --set-enabled powertools; else dnf config-manager --set-enabled crb; fi
dnf -y -q install rpm-build git perl make gcc elfutils-libelf-devel \
  kernel-rpm-macros redhat-rpm-config bzip2 cpio kernel-devel
KVERSION=$(rpm -q --qf '%{VERSION}-%{RELEASE}\n' kernel-devel | sort -V | tail -1)
echo "kernel-devel $KVERSION, $(rpm -q kernel-rpm-macros)" | annotate notice "build kernel"

# --- beegfs-client RPM ------------------------------------------------------
curl -fsSL -o /etc/yum.repos.d/beegfs.repo \
  "https://www.beegfs.io/release/beegfs_${BEEGFS_VERSION}/dists/beegfs-rhel${EL}.repo"
dnf -q download --destdir "$WORK" beegfs-client
CLIENT_RPM=$(ls "$WORK"/beegfs-client-*.rpm)
rpm -qlp "$CLIENT_RPM" > "$OUT/beegfs-client.files"
{ grep -v '^/opt/beegfs/src/' "$OUT/beegfs-client.files" || true; } | annotate notice "beegfs-client files (excluding sources)"
{ grep -o '^/opt/beegfs/src/client/[^/]*' "$OUT/beegfs-client.files" || true; } | sort -u | annotate notice "client module source dirs"
rpm -qp --requires "$CLIENT_RPM" | annotate notice "beegfs-client Requires"

( cd "$WORK" && rpm2cpio "$CLIENT_RPM" | cpio -idm --quiet )
for f in usr/lib/systemd/system/beegfs-client.service etc/beegfs/beegfs-client-autobuild.conf; do
  if [ -f "$WORK/$f" ]; then
    { grep -v -e '^\s*#' -e '^\s*$' "$WORK/$f" || true; } | annotate notice "/$f"
  else
    echo "not in beegfs-client" | annotate notice "/$f"
  fi
done

# --- beegfs-kmod ------------------------------------------------------------
git clone -q https://gitlab.com/ccad/beegfs-kmod.git "$WORK/beegfs-kmod"
KMOD_SHA=$(git -C "$WORK/beegfs-kmod" rev-parse HEAD)
echo "beegfs-kmod commit $KMOD_SHA" | annotate notice "beegfs-kmod"
summary "### EL$EL / BeeGFS $BEEGFS_VERSION"
summary "- kernel-devel: \`$KVERSION\`, beegfs-kmod: \`$KMOD_SHA\`"

cd "$WORK/beegfs-kmod"
if ! ./build-srpm.sh "$CLIENT_RPM" > "$OUT/build-srpm.log" 2>&1; then
  tail -40 "$OUT/build-srpm.log" | annotate error "build-srpm.sh failed"
  summary "- build-srpm.sh: **failed**"
  exit 1
fi
SRPM=$(ls ~/rpmbuild/SRPMS/*.src.rpm)
if ! rpmbuild --rebuild --define "kversion $KVERSION" "$SRPM" > "$OUT/rpmbuild.log" 2>&1; then
  tail -60 "$OUT/rpmbuild.log" | annotate error "rpmbuild failed"
  summary "- rpmbuild: **failed**"
  exit 1
fi
{ grep -i -E 'rdma|ibverbs|ofed|warning:' "$OUT/rpmbuild.log" || true; } | sort -u | head -40 | annotate notice "rpmbuild RDMA/warnings"

KMOD_RPM=$(ls ~/rpmbuild/RPMS/*/kmod-beegfs-*.rpm)
cp "$KMOD_RPM" "$OUT/"
summary "- built: \`$(basename "$KMOD_RPM")\`"
rpm -qlp "$KMOD_RPM" | tee "$OUT/kmod.files" | annotate notice "kmod-beegfs files"
{ echo "Provides:"; rpm -qp --provides "$KMOD_RPM"; echo "Requires:"; rpm -qp --requires "$KMOD_RPM"
  echo "Conflicts:"; rpm -qp --conflicts "$KMOD_RPM"; } | annotate notice "kmod-beegfs deps"

# Files beegfs-client ships (minus sources/build) that kmod-beegfs lacks
comm -23 <(grep -v -E '^/opt/beegfs/src(/|$)' "$OUT/beegfs-client.files" | sort) \
         <(sort "$OUT/kmod.files") > "$OUT/missing.files" || true
if [ -s "$OUT/missing.files" ]; then
  annotate warning "in beegfs-client but not kmod-beegfs" < "$OUT/missing.files"
  summary "- missing vs beegfs-client: $(wc -l < "$OUT/missing.files") paths"
fi

# --- install test -----------------------------------------------------------
{ command -v weak-modules || echo "weak-modules: not found"; rpm -qf "$(command -v weak-modules 2>/dev/null || echo /nonexistent)" 2>&1 || true; } \
  | annotate notice "weak-modules"
TOOLS=beegfs-utils
[ "${BEEGFS_VERSION%%.*}" -ge 8 ] && TOOLS="$TOOLS beegfs-tools"
if dnf -y install "$KMOD_RPM" $TOOLS > "$OUT/install.log" 2>&1; then
  { rpm -q kmod-beegfs $TOOLS; ls -l /lib/modules/*/extra/beegfs/ /lib/modules/*/weak-updates/beegfs/ 2>&1; } \
    | annotate notice "install ok"
  summary "- install with $TOOLS: ok"
else
  tail -40 "$OUT/install.log" | annotate error "install failed"
  summary "- install with $TOOLS: **failed**"
  exit 1
fi
