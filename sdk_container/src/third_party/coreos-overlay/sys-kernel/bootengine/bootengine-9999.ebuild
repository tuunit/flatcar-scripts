# Copyright (c) 2013 CoreOS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="4"
CROS_WORKON_PROJECT="coreos/bootengine"
CROS_WORKON_LOCALNAME="bootengine"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_REPO="git://github.com"

inherit cros-workon cros-debug cros-au

DESCRIPTION="CoreOS Bootengine"
SRC_URI=""

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="
	app-arch/gzip
	app-shells/bash
	sys-apps/coreutils
	sys-apps/findutils
	sys-apps/grep
	sys-apps/kbd
	sys-apps/kexec-tools
	sys-apps/less
	sys-apps/sed
	sys-apps/systemd
	sys-apps/systemd-sysv-utils
	sys-apps/util-linux
	sys-kernel/dracut
	virtual/udev
	"
RDEPEND="${DEPEND}"

src_install() {
	insinto /usr/lib/dracut/modules.d/
	doins -r ${S}/dracut/80gptprio $modules_dir
}

# We are bad, we want to get around the sandbox.  So do the creation of the
# cpio image in pkg_postinst() where we are free to mount filesystems, chroot,
# and other fun stuff.
pkg_postinst() {
	mount -t proc proc ${ROOT}/proc || die
	mount --rbind /dev ${ROOT}/dev || die
	mount --rbind /sys ${ROOT}/sys || die
	mount --rbind /run ${ROOT}/run || die

	# The keyboard tables are all still being included, which we need to
	# figure out how to remove someday.
	chroot ${ROOT} dracut --force --no-kernel --nofscks \
		--fstab --no-compress /tmp/bootengine.cpio || die

	umount --recursive ${ROOT}/proc || die
	umount --recursive ${ROOT}/dev || die
	umount --recursive ${ROOT}/sys || die
	umount --recursive ${ROOT}/run || die

	# as we are not in src_install() insinto and doins do not work here, so
	# manually copy the file around
	cpio=${ROOT}/tmp/bootengine.cpio
	chmod 644 ${cpio} || die
	mkdir -p ${ROOT}/usr/share/bootengine/ || die
	cp ${cpio} ${ROOT}/usr/share/bootengine/ || die
	rm ${cpio} || die
}
