#!/bin/bash
HUE_BRIDGE_IP=192.168.2.8 bin/hue groups set 0 --state=on --bri=255 --sat=255 --hue=0
HUE_BRIDGE_IP=192.168.2.45 bin/hue groups set 0 --state=on --bri=255 --sat=255 --hue=25000
HUE_BRIDGE_IP=192.168.2.46 bin/hue groups set 0 --state=on --bri=255 --sat=255 --hue=45000
HUE_BRIDGE_IP=192.168.2.51 bin/hue groups set 0 --state=on --bri=255 --sat=255 --hue=17500
