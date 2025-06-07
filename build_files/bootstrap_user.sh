#!/bin/bash

set -exo pipefail

user="$(whoami)"

if ! id -u "$user" > /dev/null 2>&1; then
  echo "User $user doesn't exist"
  exit 1
fi

export BOOTSTRAP_HASKELL_NONINTERACTIVE=1
export BOOTSTRAP_HASKELL_INSTALL_HLS=1

echo "Installing haskell ..."
# TODO verify GPG signature
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org > /tmp/ghcup.sh
sha512sum --check --status <<EOF
7ccdd748d15d0b28fdf4f230be2dcb77d3a6300674e7862bf5b96293cf58bb2aad0894dffb5bd3b5e29fa1cb66adb3a3073b88067e3fc86e9fe06e5b278449f1  /tmp/ghcup.sh
EOF
chmod +x /tmp/ghcup.sh
/tmp/ghcup.sh
# Get new ghcup environment
. ~/.ghcup/env
stack install hoogle
stack install ghcid
echo "Haskell installed for user $user"

cargo install bacon

pip install --user --upgrade pyflakes pipenv nose

# Once bootstrap has completed successfully, remove it from the .bashrc
sed -i 's/systemctl --user preset bootstrap-user.service//' ~/.bashrc
