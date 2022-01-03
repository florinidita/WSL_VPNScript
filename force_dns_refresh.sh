#!/bin/bash

# This script fixes /etc/resolv.conf to address an issue where DNS is not updated in WSL.
# Refer to https://github.com/Microsoft/WSL/issues/1350 for more information.

# Instructions:
# 1. Connect to the VPN.
# 2. Use "force_dns_refresh" command into your WSL container

force_dns_refresh() {
    echo "------------------------------------------"
    echo "Update resolv.conf with Windows settings"
    echo "------------------------------------------"

    tmp_resolveconf=`mktemp`
    # In case if C: is mounted somewhere else. My case is /c instead /mnt/c
    powershell=$(wslpath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe")

    dnssrvlist=`$powershell -Command '$x = Get-NetAdapter | Group-Object -AsHashtable -Property ifIndex; Get-DnsClientServerAddress -AddressFamily ipv4 | where {$x[$_.InterfaceIndex].Status -eq "Up"} | Select-Object -ExpandProperty ServerAddresses' | sed 's/\r//g'`
    {
        head -1 /etc/resolv.conf | grep '^#.*generated'
        tail -n+2 /etc/resolv.conf | grep -v '^nameserver'
        for i in $dnssrvlist; do
            echo nameserver $i
        done
    } | tr -d '\r' > $tmp_resolveconf


    cat $tmp_resolveconf
    sudo cp $tmp_resolveconf /etc/resolv.conf

    echo "Done!"
}
