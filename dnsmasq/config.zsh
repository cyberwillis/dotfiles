#!/bin/bash -e

if [[ "$(systemctl status dnsmasq | grep Active | cut -d':' -f2 | cut -d' ' -f2)" == "failed" ]]; then
    sudo systemctl restart dnsmasq;
fi