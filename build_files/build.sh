#!/bin/bash

set -ouex pipefail

### Set up OS info

IMAGE_PRETTY_NAME="Hackberry"
HOME_URL="https://github.com/setupminimal/hackberry/"
DOCUMENTATION_URL="https://github.com/setupminimal/hackberry"
SUPPORT_URL="https://github.com/setupminimal/hackberry/issues"
BUG_SUPPORT_URL="https://github.com/setupminimal/hackberry/issues"
VERSION="${VERSION:-00.00000000}"

IMAGE_INFO="/usr/share/ublue-os/image-info.json"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/$IMAGE_VENDOR/$IMAGE_NAME"

cat >$IMAGE_INFO <<EOF
{
  "image-name": "$IMAGE_NAME",
  "image-flavor": "plain",
  "image-vendor": "$IMAGE_VENDOR",
  "image-ref": "$IMAGE_REF",
  "image-tag":"$UBLUE_IMAGE_TAG",
  "base-image-name": "$BASE_IMAGE_NAME",
  "fedora-version": "$FEDORA_MAJOR_VERSION"
}
EOF

# OS Release File
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"${IMAGE_PRETTY_NAME} (Version: ${VERSION} / FROM Fedora ${BASE_IMAGE_NAME^} $FEDORA_MAJOR_VERSION)\"|" /usr/lib/os-release
sed -i "s|^NAME=.*|NAME=\"$IMAGE_PRETTY_NAME\"|" /usr/lib/os-release
sed -i "s|^HOME_URL=.*|HOME_URL=\"$HOME_URL\"|" /usr/lib/os-release
sed -i "s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"$DOCUMENTATION_URL\"|" /usr/lib/os-release
sed -i "s|^SUPPORT_URL=.*|SUPPORT_URL=\"$SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"$BUG_SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^CPE_NAME=\"cpe:/o:fedoraproject:fedora|CPE_NAME=\"cpe:/o:universal-blue:${IMAGE_PRETTY_NAME,}|" /usr/lib/os-release
sed -i "s|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME=\"${IMAGE_PRETTY_NAME,}\"|" /usr/lib/os-release
sed -i "s|^ID=.*|ID=${IMAGE_PRETTY_NAME,}|" /usr/lib/os-release
sed -i "/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d" /usr/lib/os-release
sed -i "s|^VERSION=.*|VERSION=\"${VERSION} (${BASE_IMAGE_NAME^})\"|" /usr/lib/os-release
sed -i "s|^OSTREE_VERSION=.*|OSTREE_VERSION=\'${VERSION}\'|" /usr/lib/os-release

if [[ -n "${SHA_HEAD_SHORT:-}" ]]; then
echo "BUILD_ID=\"$SHA_HEAD_SHORT\"" >>/usr/lib/os-release
fi

# Added in systemd 249.
# https://www.freedesktop.org/software/systemd/man/latest/os-release.html#IMAGE_ID=
echo "IMAGE_ID=\"${IMAGE_NAME}\"" >> /usr/lib/os-release
echo "IMAGE_VERSION=\"${VERSION}\"" >> /usr/lib/os-releae

### Install packages

true || dnf install -y feh mpv strace python3-devel htop calibre evince clang emacs g++\
    gnome-boxes rustup virtualenv flex bison ruby rust rust-src bindgen-cli\
    rustfmt clippy elfutils-libelf-devel ripgrep jq editorconfig npm idris julia\
    fd-find zig racket sbcl black python3-isort python3-pytest shellcheck shfmt\
    clang-tools-extra gcc gcc-c++ gmp gmp-devel make ncurses ncurses-compat-libs\
    xz perl pkg-config tidy rbenv firefox claws-mail btrbk aspell ImageMagick

#     postgresql postgresql-server postgresql-contrib libpq-devel python3-bcrypt\
#     aspell ImageMagick httpd mod_http2


wget https://builds.zigtools.org/zls-linux-x86_64-0.13.0.tar.xz
sha512sum --check --status <<EOF
21541d5f0e77b840aaa5ffb834bc0feaf72df86902af62682f4023f6a77c4653177900ceb122e7363954a40935ab435984a1ff7fa2219602576d4db7f6d65b1b  zls-linux-x86_64-0.13.0.tar.xz
EOF
# If the check fails, then --status should mean the script fails too.
tar xvf zls*
mv zls /usr/bin

dnf install -y npm

# npm tries to put logs here and gets cranky if it can't.
mkdir /var/roothome/

mkdir /usr/share/npm-global
export NPM_CONFIG_PREFIX=/usr/share/npm-global
npm install -g stylelint js-beautify --loglevel=verbose

echo "export PATH=/usr/share/npm-global/bin:\$PATH" >> /etc/bashrc


mkdir /usr/share/python-global
export PIP_PREFIX=/usr/share/python-global
pip install pyflakes pipenv nose

echo "export PAHT=/usr/share/python-global/bin:\$PATH" >> /etc/bashrc

rm -rf /var/roothome/*

### Install direnv by default

echo 'eval $\(direnv hook bash\)' >> /etc/bashrc


### Put back the fedora themeing


dnf -y swap aurora-logos fedora-logos



### Install per-user setup

cat > /usr/lib/systemd/system/bootstrap-user@.service <<EOF
[Unit]
Description=Bootstrap per-user setup for user %i
After=user@%i.service

[Service]
Type=simple
User=%i
Group=%i
ExecStart=/usr/bin/bootstrap-user %i
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

cat > /usr/bin/bootstrap-user <<EOF
#!/bin/bash

user="\$1"

if [ -z "\$user" ]; then
  echo "Usage: \$0 <username>"
  exit 1
fi

if ! id -u "\$user" > /dev/null 2>&1; then
  echo "User \$user doesn't exist"
  exit 1
fi

export BOOTSTRAP_HASKELL_NONINTERACTIVE=1
export BOOTSTRAP_HASKELL_INSTALL_HLS=1

echo "Installing haskell ..."
# TODO verify GPG signature
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
stack install hoogle
echo "Haskell installed for user \$user"
EOF

chmod +x /usr/bin/bootstrap-user

cat > /usr/lib/systemd/system/bootstrap-users.service <<EOF
[Unit]
Description=Bootstrap all users
After=syslog.target
Before=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/bootstrap-all-users

[Install]
WantedBy=multi-user.target
EOF

cat > /usr/bin/bootstrap-all-users <<EOF
#!/bin/bash

# Get a list of users (excluding system users - UID < 1000)
users=$\(getent passwd | awk -F: '\$3 >= 1000 {print \$1}')

for user in \$users; do
  echo "Instantiating Haskell bootstrap for user: \$user"
  systemd --user run --scope bootstrap-user@"\$user".service
done
EOF

chmod +x /usr/bin/bootstrap-all-users
