abbr -a bat 'batcat'
# El núcleo: gestión de servicios de usuario
abbr -a scu  'systemctl --user'
abbr -a dr   'systemctl --user daemon-reload'
abbr -a scr  'systemctl --user restart'
abbr -a scs  'systemctl --user start'
abbr -a sck  'systemctl --user stop'
abbr -a scl  'systemctl --user status'
# Inspecciona
abbr -a qi '/usr/libexec/podman/quadlet -user -dryrun'
# Propios de fish
abbr -a fr 'source ~/.config/fish/config.fish'
