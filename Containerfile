# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
# FROM ghcr.io/ublue-os/aurora-dx:latest
FROM ghcr.io/ublue-os/kinoite-main:latest

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

# TODO figure out how to selectively inherit these from aurora
ARG IMAGE_NAME="hackberry"
ARG IMAGE_VENDOR="setupminimal"
ARG UBLUE_IMAGE_TAG="latest"
ARG BASE_IMAGE_NAME="kinoite"
ARG FEDORA_MAJOR_VERSION="42"

### MODIFICATIONS
## the following RUN directive does all the things required to run "build.sh" as recommended.

# In separate RUN statement so that it ends up cached in a separate layer
RUN dnf -y copr enable tulilirockz/fw-fanctrl && \
    dnf install -y feh mpv strace python3-devel htop calibre evince clang \
    emacs g++ gnome-boxes rustup virtualenv flex bison ruby rust rust-src \
    bindgen-cli rustfmt clippy elfutils-libelf-devel ripgrep jq editorconfig \
    npm idris julia fd-find zig racket sbcl black python3-isort python3-pytest \
    shellcheck shfmt clang-tools-extra gcc gcc-c++ gmp gmp-devel make ncurses \
    ncurses-compat-libs xz perl pkg-config tidy rbenv firefox claws-mail btrbk \
    aspell ImageMagick dnf-plugins-core wget cmake direnv marked fw-ectool sway \
    tailscale && \
    dnf -y clean all

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
