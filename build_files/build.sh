#!/bin/bash

set -ouex pipefail

### Install packages

dnf install -y feh mpv strace python3-devel htop calibre evince clang emacs g++\
    gnome-boxes rustup virtualenv flex bison ruby rust rust-src bindgen-cli\
    rustfmt clippy elfutils-libelf-devel ripgrep jq editorconfig npm idris julia\
    fd-find zig racket sbcl black python3-isort python3-pytest shellcheck shfmt\
    clang-tools-extra gcc gcc-c++ gmp gmp-devel make ncurses ncurses-compat-libs\
    xz perl pkg-config tidy rbenv \
    postgresql postgresql-server postgresql-contrib libpq-devel python3-bcrypt\
    aspell ImageMagick httpd mod_http2

wget https://builds.zigtools.org/zls-linux-x86_64-0.13.0.tar.xz
sha512sum --check --status <<EOF
21541d5f0e77b840aaa5ffb834bc0feaf72df86902af62682f4023f6a77c4653177900ceb122e7363954a40935ab435984a1ff7fa2219602576d4db7f6d65b1b  zls-linux-x86_64-0.13.0.tar.xz
EOF
# If the check fails, then --status should mean the script fails too.
tar xvf zls*
mv zls /usr/bin
