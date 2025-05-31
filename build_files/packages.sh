#!/usr/bin/env sh

### Install packages
### In a separate file so that it will produce two different layers, and spare
### upstream's servers.

dnf install -y feh mpv strace python3-devel htop calibre evince clang emacs g++ gnome-boxes rustup virtualenv flex bison ruby rust rust-src bindgen-cli rustfmt clippy elfutils-libelf-devel ripgrep jq editorconfig npm idris julia fd-find zig racket sbcl black python3-isort python3-pytest shellcheck shfmt clang-tools-extra gcc gcc-c++ gmp gmp-devel make ncurses ncurses-compat-libs xz perl pkg-config tidy rbenv firefox claws-mail btrbk aspell ImageMagick


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

echo "export PATH=/usr/share/npm-global/bin:\$PATH" >>/etc/bashrc

mkdir /usr/share/python-global
export PIP_PREFIX=/usr/share/python-global
pip install pyflakes pipenv nose

echo "export PATH=/usr/share/python-global/bin:\$PATH" >>/etc/bashrc

rm -rf /var/roothome/* /var/roothome/.*

mkdir /var/roothome/.gnupg
