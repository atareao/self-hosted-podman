function jcu --description "Logs limpios con bat y ansifilter"
    journalctl --user -xeu $argv[1] --no-pager | ansifilter | batcat -l log
end
