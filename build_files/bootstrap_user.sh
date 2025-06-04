#!/bin/bash

set -eo pipefail

user="$(whoami)"

if ! id -u "$user" > /dev/null 2>&1; then
  echo "User $user doesn't exist"
  exit 1
fi

if ! [ -d "$HOME/.ghcup" ]; then
    export BOOTSTRAP_HASKELL_NONINTERACTIVE=1
    export BOOTSTRAP_HASKELL_INSTALL_HLS=1

    echo "Installing haskell ..."
    # TODO verify GPG signature
    curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
    stack install hoogle
    echo "Haskell installed for user $user"
fi

# Once bootstrap has completed successfully, remove it from the .bashrc
sed -i 's/systemctl --user preset bootstrap-user.service//' ~/.bashrc
