#!/bin/bash

set -ouex pipefail

### Set up OS info

IMAGE_PRETTY_NAME="Hackberry"
HOME_URL="https://github.com/setupminimal/hackberry/"
DOCUMENTATION_URL="https://github.com/setupminimal/hackberry"
SUPPORT_URL="https://github.com/setupminimal/hackberry/issues"
BUG_SUPPORT_URL="https://github.com/setupminimal/hackberry/issues"
VERSION="${VERSION:-$(date --rfc-3339=date)}"

# OS Release File
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"${IMAGE_PRETTY_NAME} (Version: ${VERSION} / FROM Fedora ${BASE_IMAGE_NAME^} $FEDORA_MAJOR_VERSION)\"|" /usr/lib/os-release
sed -i "s|^NAME=.*|NAME=\"$IMAGE_PRETTY_NAME\"|" /usr/lib/os-release
sed -i "s|^HOME_URL=.*|HOME_URL=\"$HOME_URL\"|" /usr/lib/os-release
sed -i "s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"$DOCUMENTATION_URL\"|" /usr/lib/os-release
sed -i "s|^SUPPORT_URL=.*|SUPPORT_URL=\"$SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"$BUG_SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^CPE_NAME=\"cpe:/o:fedoraproject:fedora|CPE_NAME=\"cpe:/o:universal-blue:${IMAGE_PRETTY_NAME,}|" /usr/lib/os-release
sed -i "s|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME=\"${IMAGE_PRETTY_NAME,}\"|" /usr/lib/os-release
# Unfortunately, if we set a name here, bootc-image-builder doesn't know how to
# handle it. This can be reinstated when
# https://github.com/osbuild/bootc-image-builder/issues/816 is fixed.
#sed -i "s|^ID=.*|ID=${IMAGE_PRETTY_NAME,}|" /usr/lib/os-release
sed -i "s|^ID=.*|ID=fedora|" /usr/lib/os-release
sed -i "/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d" /usr/lib/os-release
sed -i "s|^VERSION=.*|VERSION=\"${VERSION} (${BASE_IMAGE_NAME^})\"|" /usr/lib/os-release
sed -i "s|^OSTREE_VERSION=.*|OSTREE_VERSION=\'${VERSION}\'|" /usr/lib/os-release

if [[ -n "${SHA_HEAD_SHORT:-}" ]]; then
	echo "BUILD_ID=\"$SHA_HEAD_SHORT\"" >>/usr/lib/os-release
fi

# Added in systemd 249.
# https://www.freedesktop.org/software/systemd/man/latest/os-release.html#IMAGE_ID=
echo "IMAGE_ID=\"${IMAGE_NAME}\"" >>/usr/lib/os-release
echo "IMAGE_VERSION=\"${VERSION}\"" >>/usr/lib/os-release


mkdir /nix


### Install packages


# Report on leaf packages
dnf leaves > /usr/share/leaf-packages

wget https://builds.zigtools.org/zls-linux-x86_64-0.13.0.tar.xz
sha512sum --check --status <<EOF
21541d5f0e77b840aaa5ffb834bc0feaf72df86902af62682f4023f6a77c4653177900ceb122e7363954a40935ab435984a1ff7fa2219602576d4db7f6d65b1b  zls-linux-x86_64-0.13.0.tar.xz
EOF
# If the check fails, then --status should mean the script fails too.
tar xvf zls*
mv zls /usr/bin

rm zls-linux*.tar.xz

curl -sS https://starship.rs/install.sh > /tmp/starship.sh
sha512sum --check --status <<EOF
36e0d5500f388262d7dfc4285691f408fba3071d11691a2bd3c62b830a232a04484ec59abcbe81ecd84c21cfa807d8421fae3dd85d26500168130edda550d243  /tmp/starship.sh
EOF
chmod +x /tmp/starship.sh
/tmp/starship.sh -y --bin-dir /usr/bin

# npm tries to put logs here and gets cranky if it can't.
mkdir -p /var/roothome/

mkdir /usr/share/npm-global
export NPM_CONFIG_PREFIX=/usr/share/npm-global
npm install -g stylelint js-beautify --loglevel=verbose

echo "export PATH=/usr/share/npm-global/bin:\$PATH" >>/etc/bashrc

mkdir /usr/share/python-global
export PIP_PREFIX=/usr/share/python-global
pip install pyflakes pipenv nose

echo "export PATH=/usr/share/python-global/bin:\$PATH" >>/etc/bashrc

rm -rf /var/roothome/* /var/roothome/.*

mkdir -p /var/roothome/.gnupg





# Set console settings

#sed -i 's!systemd-firstboot --prompt.*!systemd-firstboot --locale=en_US.UTF-8 --keymap=us-dvorak --timezone=America/New_York --delete-root-password!' /usr/lib/systemd/system/systemd-firstboot.service

cat > /etc/vconsole.conf <<EOF
KEYMAP="us-dvorak"
EOF

mkdir /usr/lib/systemd/system/systemd-vconsole-setup.service.d
cat > /usr/lib/systemd/system/systemd-vconsole-setup.service.d/hackberry.conf <<EOF
[Unit]
RequiredBy=default.target
EOF

# For the login manager, I think?
mkdir -p /etc/X11/xorg.conf.d/
cat > /etc/X11/xorg.conf.d/00-keyboard.conf <<EOF
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "us"
        Option "XkbModel" "pc105"
        Option "XkbVariant" "dvorak"
EndSection
EOF


mkdir -p /etc/skel/.config/
cat > /etc/skel/.config/kxkbrc <<EOF
[Layout]
LayoutList=us
Use=true
VariantList=dvorak
Options=compose:caps
ResetOldOptions=true
EOF


ln -s ../usr/share/zoneinfo/America/New_York /etc/localtime

cat > /etc/locale.conf <<EOF
LANG="en_US.UTF-8"
EOF

### Systemd optimizations

systemctl disable NetworkManager-wait-online.service
cat >/usr/lib/systemd/journald.conf.d/01-limit-size.conf <<EOF
[Journal]
SystemMaxUse=50M
EOF

### That damn light

cat >/usr/lib/systemd/system/disable-light.service <<EOF
[Unit]
Description=Turn off framework power light

[Service]
Type=simple
ExecStart=/usr/bin/ectool led power off

[Install]
WantedBy=default.target
EOF

cat >>/usr/lib/systemd/system-preset/50-hackberry.preset <<EOF
enable disable-light.service
EOF

### Install per-user setup

cat >/usr/lib/systemd/user/bootstrap-user.service <<EOF
[Unit]
Description=Bootstrap per-user setup for user
ConditionUser=!@system
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/bootstrap-user

[Install]
WantedBy=default.target
EOF

cat >>/usr/lib/systemd/user-preset/50-hackberry.preset <<EOF
enable bootstrap-user.service
EOF

cp /ctx/bootstrap_user.sh /usr/bin/bootstrap-user
chmod +x /usr/bin/bootstrap-user
