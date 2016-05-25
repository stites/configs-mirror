if [ -n "$HOME" ]; then
    NIX_LINK="$HOME/.nix-profile"

    # Set the default profile.
    if ! [ -L "$NIX_LINK" ]; then
        echo "creating $NIX_LINK" >&2
        _NIX_DEF_LINK=/nix/var/nix/profiles/default
        /nix/store/kd9774cj5vj2zl7gfx2bs30j9qiaiqpq-coreutils-8.24/bin/ln -s "$_NIX_DEF_LINK" "$NIX_LINK"
    fi

    export PATH=$NIX_LINK/bin:$NIX_LINK/sbin:$PATH

    # Subscribe the user to the Nixpkgs channel by default.
    if [ ! -e $HOME/.nix-channels ]; then
        echo "https://nixos.org/channels/nixpkgs-unstable nixpkgs" > $HOME/.nix-channels
    fi

    # Append ~/.nix-defexpr/channels/nixpkgs to $NIX_PATH so that
    # <nixpkgs> paths work when the user has fetched the Nixpkgs
    # channel.
    export NIX_PATH=${NIX_PATH:+$NIX_PATH:}nixpkgs=$HOME/.nix-defexpr/channels/nixpkgs

    # Set $SSL_CERT_FILE so that Nixpkgs applications like curl work.
    if [ -e /etc/ssl/certs/ca-certificates.crt ]; then # NixOS, Ubuntu, Debian, Gentoo, Arch
        export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
    elif [ -e /etc/ssl/certs/ca-bundle.crt ]; then # Old NixOS
        export SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
    elif [ -e /etc/pki/tls/certs/ca-bundle.crt ]; then # Fedora, CentOS
        export SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt
    elif [ -e "$NIX_LINK/etc/ssl/certs/ca-bundle.crt" ]; then # fall back to cacert in Nix profile
        export SSL_CERT_FILE="$NIX_LINK/etc/ssl/certs/ca-bundle.crt"
    elif [ -e "$NIX_LINK/etc/ca-bundle.crt" ]; then # old cacert in Nix profile
        export SSL_CERT_FILE="$NIX_LINK/etc/ca-bundle.crt"
    fi
fi
