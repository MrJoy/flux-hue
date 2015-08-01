#!/bin/bash
HUE_BRIDGE_IP=192.168.2.10 bin/hue groups set 0 --state=off
HUE_BRIDGE_IP=192.168.2.6 bin/hue groups set 0 --state=off
HUE_BRIDGE_IP=192.168.2.7 bin/hue groups set 0 --state=off
HUE_BRIDGE_IP=192.168.2.9 bin/hue groups set 0 --state=off
