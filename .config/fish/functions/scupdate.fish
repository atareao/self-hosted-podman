function scupdate
    systemctl --user daemon-reload
    systemctl --user restart $argv
end
