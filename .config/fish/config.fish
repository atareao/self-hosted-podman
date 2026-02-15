if status is-interactive
    if test -d ~/.local/bin
        fish_add_path ~/.local/bin
    end
    # zoxide
    zoxide init fish | source
    # starship
    starship init fish | source
    set -gx SOPS_AGE_KEY_FILE "$HOME/.secrets/sops/age/key.txt"
end 
