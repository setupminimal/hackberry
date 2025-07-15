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
dd7ae2086567f5b9a684f5f2302f530df6f816d1865c4f867cf26906721fa7d5ccfdd2b28fee66c96cf08ccf6f967e01459b5b10f432e645d19953dd5c5472d3 /tmp/ghcup.sh
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
