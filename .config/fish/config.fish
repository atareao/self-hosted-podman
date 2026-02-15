if status is-interactive
    # Commands to run in interactive sessions can go here
    # zoxide
    zoxide init fish | source
    # starship
    starship init fish | source
    set -gx SOPS_AGE_KEY_FILE "$HOME/.secrets/sops/age/key.txt"
end 
