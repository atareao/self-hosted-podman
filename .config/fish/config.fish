if status is-interactive
    set -gx XDG_RUNTIME_DIR /run/user/(id -u)
    set -gx DBUS_SESSION_BUS_ADDRESS unix:path=$XDG_RUNTIME_DIR/bus
    if test -d ~/.local/bin
        fish_add_path ~/.local/bin
    end
    # zoxide
    zoxide init fish | source
    # starship
    starship init fish | source
    set -gx SOPS_AGE_KEY_FILE "$HOME/.secrets/sops/age/key.txt"
end 
