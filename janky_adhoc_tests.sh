#!/bin/bash
IFS=$'\n\t'
# set -x

mkdir -p tmp

# TODO: Factor this in: http://steveyo.github.io/Hue-Emulator/

export ERRORS=0

COMMAND="bridges"
SUBCOMMAND="discover"
HUE_SKIP_NUPNP=1 HUE_SKIP_SSDP=1 HUE_BRIDGE_IP=192.168.2.8 bin/hue ${COMMAND} ${SUBCOMMAND} > tmp/${COMMAND}_${SUBCOMMAND}_explicit_ip.txt 2>&1
HUE_SKIP_NUPNP=1 HUE_SKIP_SSDP= HUE_BRIDGE_IP= bin/hue ${COMMAND} ${SUBCOMMAND} > tmp/${COMMAND}_${SUBCOMMAND}_ssdp.txt 2>&1
HUE_SKIP_NUPNP= HUE_SKIP_SSDP=1 HUE_BRIDGE_IP= bin/hue ${COMMAND} ${SUBCOMMAND} > tmp/${COMMAND}_${SUBCOMMAND}_upnp.txt 2>&1
RESULT=$(diff -u tmp/${COMMAND}_${SUBCOMMAND}_explicit_ip.txt tmp/${COMMAND}_${SUBCOMMAND}_ssdp.txt | grep -v -E '^(---|\+\+\+|@@| )')
if [[ $RESULT != "+INFO: Discovering bridges via SSDP..." ]]; then
  echo "FAIL: \`hue ${COMMAND} ${SUBCOMMAND}\` produced unexpected resultss for explicit IP vs. SSDP."
  export ERRORS=$((ERRORS + 1))
else
  echo "PASS: \`hue ${COMMAND} ${SUBCOMMAND}\` Explicit IP and SSDP discovery are equivalent."
fi

RESULT=$(diff -u tmp/${COMMAND}_${SUBCOMMAND}_explicit_ip.txt tmp/${COMMAND}_${SUBCOMMAND}_upnp.txt | grep -v -E '^(---|\+\+\+|@@| )')
if [[ $RESULT != "+INFO: Discovering bridges via N-UPnP..." ]]; then
  echo "FAIL: \`hue ${COMMAND} ${SUBCOMMAND}\` produced unexpected resultss for explicit IP vs. N-UPnP."
  export ERRORS=$((ERRORS + 1))
else
  echo "PASS: \`hue ${COMMAND} ${SUBCOMMAND}\` Explicit IP and N-UPnP discovery are equivalent."
fi
# Baseline:
# +--------------+-----------+-------------+-------------------+-------------+------------------+
# | ID           | Name      | IP          | MAC               | API Version | Software Version |
# +--------------+-----------+-------------+-------------------+-------------+------------------+
# | 0017881226f3 | Bridge-01 | 192.168.2.8 | 00:17:88:12:26:f3 | 1.7.0       | 01023599         |
# +--------------+-----------+-------------+-------------------+-------------+------------------+


COMMAND="bridges"
SUBCOMMAND="inspect"
HUE_SKIP_NUPNP=1 HUE_SKIP_SSDP=1 HUE_BRIDGE_IP=192.168.2.8 bin/hue ${COMMAND} ${SUBCOMMAND} > tmp/${COMMAND}_${SUBCOMMAND}_explicit_ip.txt 2>&1
HUE_SKIP_NUPNP=1 HUE_SKIP_SSDP= HUE_BRIDGE_IP= bin/hue ${COMMAND} ${SUBCOMMAND} > tmp/${COMMAND}_${SUBCOMMAND}_ssdp.txt 2>&1
HUE_SKIP_NUPNP= HUE_SKIP_SSDP=1 HUE_BRIDGE_IP= bin/hue ${COMMAND} ${SUBCOMMAND} > tmp/${COMMAND}_${SUBCOMMAND}_upnp.txt 2>&1
RESULT=$(diff -u tmp/${COMMAND}_${SUBCOMMAND}_explicit_ip.txt tmp/${COMMAND}_${SUBCOMMAND}_ssdp.txt | grep -v -E '^(---|\+\+\+|@@| )')
if [[ $RESULT != "+INFO: Discovering bridges via SSDP..." ]]; then
  echo "FAIL: \`hue ${COMMAND} ${SUBCOMMAND}\` produced unexpected resultss for explicit IP vs. SSDP."
  export ERRORS=$((ERRORS + 1))
else
  echo "PASS: \`hue ${COMMAND} ${SUBCOMMAND}\` Explicit IP and SSDP discovery are equivalent."
fi

RESULT=$(diff -u tmp/${COMMAND}_${SUBCOMMAND}_explicit_ip.txt tmp/${COMMAND}_${SUBCOMMAND}_upnp.txt | grep -v -E '^(---|\+\+\+|@@| )')
if [[ $RESULT != "+INFO: Discovering bridges via N-UPnP..." ]]; then
  echo "FAIL: \`hue ${COMMAND} ${SUBCOMMAND}\` produced unexpected resultss for explicit IP vs. N-UPnP."
  export ERRORS=$((ERRORS + 1))
else
  echo "PASS: \`hue ${COMMAND} ${SUBCOMMAND}\` Explicit IP and N-UPnP discovery are equivalent."
fi
# Baseline:
# +--------------+-------------+-------------------+-----------+---------+---------------+-------------+-------+---------------+------------+------------------+----------------------+--------------+-------------+------------------+------------------------+---------+
# | ID           | IP          | MAC               | Name      | Channel | Net Mask      | Gateway     | DHCP? | Proxy Address | Proxy Port | Portal Services? | Connected to Portal? | Portal State | API Version | Software Version | Update Info            | Button? |
# +--------------+-------------+-------------------+-----------+---------+---------------+-------------+-------+---------------+------------+------------------+----------------------+--------------+-------------+------------------+------------------------+---------+
# | 0017881226f3 | 192.168.2.8 | 00:17:88:12:26:f3 | Bridge-01 | 25      | 255.255.255.0 | 192.168.2.1 | true  | none          | 0          | true             | connected            |              | 1.7.0       | 01023599         | HUE0100 lamp 66013452  | false   |
# +--------------+-------------+-------------------+-----------+---------+---------------+-------------+-------+---------------+------------+------------------+----------------------+--------------+-------------+------------------+------------------------+---------+



COMMAND="lights"
SUBCOMMAND="inspect"
HUE_SKIP_NUPNP=1 HUE_SKIP_SSDP=1 HUE_BRIDGE_IP=192.168.2.8 bin/hue ${COMMAND} ${SUBCOMMAND} > tmp/${COMMAND}_${SUBCOMMAND}_explicit_ip.txt 2>&1
HUE_SKIP_NUPNP=1 HUE_SKIP_SSDP= HUE_BRIDGE_IP= bin/hue ${COMMAND} ${SUBCOMMAND} > tmp/${COMMAND}_${SUBCOMMAND}_ssdp.txt 2>&1
HUE_SKIP_NUPNP= HUE_SKIP_SSDP=1 HUE_BRIDGE_IP= bin/hue ${COMMAND} ${SUBCOMMAND} > tmp/${COMMAND}_${SUBCOMMAND}_upnp.txt 2>&1
RESULT=$(diff -u tmp/${COMMAND}_${SUBCOMMAND}_explicit_ip.txt tmp/${COMMAND}_${SUBCOMMAND}_ssdp.txt | grep -v -E '^(---|\+\+\+|@@| )')
if [[ $RESULT != "+INFO: Discovering bridges via SSDP..." ]]; then
  echo "FAIL: \`hue ${COMMAND} ${SUBCOMMAND}\` produced unexpected resultss for explicit IP vs. SSDP."
  export ERRORS=$((ERRORS + 1))
else
  echo "PASS: \`hue ${COMMAND} ${SUBCOMMAND}\` Explicit IP and SSDP discovery are equivalent."
fi

RESULT=$(diff -u tmp/${COMMAND}_${SUBCOMMAND}_explicit_ip.txt tmp/${COMMAND}_${SUBCOMMAND}_upnp.txt | grep -v -E '^(---|\+\+\+|@@| )')
if [[ $RESULT != "+INFO: Discovering bridges via N-UPnP..." ]]; then
  echo "FAIL: \`hue ${COMMAND} ${SUBCOMMAND}\` produced unexpected resultss for explicit IP vs. N-UPnP."
  export ERRORS=$((ERRORS + 1))
else
  echo "PASS: \`hue ${COMMAND} ${SUBCOMMAND}\` Explicit IP and N-UPnP discovery are equivalent."
fi
# Baseline:
# +----+----------------------+--------+----------------------+--------+------+-------+------------+------------+----------------+------+---------+--------+------------------+------------+
# | ID | Type                 | Model  | Name                 | Status | Mode | Hue   | Saturation | Brightness | X/Y            | Temp | Alert   | Effect | Software Version | Reachable? |
# +----+----------------------+--------+----------------------+--------+------+-------+------------+------------+----------------+------+---------+--------+------------------+------------+
# | 1  | Extended color light | LCT002 | TV-Left-Upper        | On     | hs   | 65535 | 254        | 205        | 0.6750, 0.3220 | 500  | none    | none   | 66013452         | Yes        |
# | 2  | Extended color light | LCT002 | TV-Right-Upper       | On     | xy   | 40907 | 253        | 247        | 0.2372, 0.1785 | 500  | none    | none   | 66013452         | Yes        |
# | 3  | Dimmable light       | LWB004 | Kitchen-02           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | Yes        |
# | 4  | Dimmable light       | LWB004 | Kitchen-03           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | Yes        |
# | 5  | Dimmable light       | LWB004 | Kitchen-01           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | Yes        |
# | 6  | Extended color light | LCT002 | TV-Left-Lower        | On     | xy   | 40834 | 253        | 236        | 0.2381, 0.1802 | 500  | none    | none   | 66013452         | Yes        |
# | 7  | Extended color light | LCT002 | Lab-Back-Right       | On     | hs   | 35215 | 254        | 180        | 0.3008, 0.3042 | 153  | none    | none   | 66013452         | Yes        |
# | 8  | Extended color light | LCT002 | Lab-Back-Center      | On     | xy   | 38360 | 253        | 208        | 0.2658, 0.2349 | 153  | none    | none   | 66013452         | Yes        |
# | 9  | Color light          | LLC011 | Entryway-Back        | On     | xy   | 41059 | 106        | 165        | 0.3155, 0.3171 |      | none    | none   | 66013452         | Yes        |
# | 10 | Color light          | LLC011 | Entryway-Middle      | On     | xy   | 42891 | 67         | 246        | 0.3584, 0.3379 |      | none    | none   | 66009461         | Yes        |
# | 11 | Color light          | LST001 | Bed-Right-Lower      | On     | xy   | 40994 | 193        | 182        | 0.2175, 0.2461 |      | none    | none   | 66013452         | Yes        |
# | 12 | Color light          | LST001 | Bed-Left-Lower       | On     | xy   | 40677 | 130        | 187        | 0.2890, 0.3026 |      | none    | none   | 66013452         | Yes        |
# | 13 | Color light          | LST001 | Entryway-Front       | On     | xy   | 39894 | 109        | 249        | 0.3134, 0.3288 |      | none    | none   | 66013452         | Yes        |
# | 14 | Extended color light | LCT002 | TV-Right-Lower       | On     | xy   | 36495 | 253        | 169        | 0.2868, 0.2762 | 153  | none    | none   | 66010673         | Yes        |
# | 15 | Extended color light | LCT002 | Lab-Back-Left        | On     | xy   | 40723 | 252        | 239        | 0.2399, 0.1834 | 500  | none    | none   | 66010673         | Yes        |
# | 16 | Dimmable light       | LWB004 | Kitchen-04           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | Yes        |
# | 17 | Extended color light | LCT002 | Bed-Left-Upper       | On     | xy   | 41106 | 252        | 144        | 0.2356, 0.1749 | 500  | none    | none   | 66010673         | Yes        |
# | 18 | Extended color light | LCT002 | Lab-Middle-Left      | On     | xy   | 36139 | 254        | 219        | 0.2904, 0.2837 | 153  | none    | none   | 66010673         | Yes        |
# | 19 | Extended color light | LCT002 | Lab-Front-Left       | On     | xy   | 38320 | 253        | 193        | 0.2663, 0.2358 | 153  | none    | none   | 66013452         | Yes        |
# | 20 | Extended color light | LCT002 | Bed-Right-Upper      | On     | xy   | 34486 | 237        | 215        | 0.3138, 0.3243 | 153  | none    | none   | 66010673         | Yes        |
# | 21 | Extended color light | LCT002 | Bed-Center-Upper     | On     | xy   | 39407 | 253        | 168        | 0.2541, 0.2117 | 153  | none    | none   | 66010673         | Yes        |
# | 22 | Extended color light | LCT002 | Library-Middle       | On     | hs   | 38256 | 253        | 238        | 0.2670, 0.2372 | 153  | none    | none   | 66010673         | Yes        |
# | 23 | Extended color light | LCT002 | Library-Front        | On     | xy   | 40881 | 253        | 237        | 0.2376, 0.1791 | 500  | none    | none   | 66013452         | Yes        |
# | 24 | Dimmable light       | LWB004 | Kitchen-05           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | Yes        |
# | 25 | Dimmable light       | LWB004 | Kitchen-06           | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | Yes        |
# | 26 | Extended color light | LCT002 | Lab-Front-Right      | On     | xy   | 38541 | 253        | 236        | 0.2638, 0.2309 | 153  | none    | none   | 66010673         | Yes        |
# | 27 | Extended color light | LCT002 | Lab-Middle-Right     | On     | xy   | 40714 | 252        | 235        | 0.2400, 0.1836 | 500  | none    | none   | 66010673         | Yes        |
# | 28 | Extended color light | LCT002 | Lab-09               | On     | xy   | 35470 | 253        | 221        | 0.2982, 0.2989 | 153  | none    | none   | 66010673         | Yes        |
# | 29 | Dimmable light       | LWB004 | Misc-01              | Off    |      |       |            | 254        |                |      | lselect |        | 66012040         | No         |
# | 30 | Extended color light | LCT002 | Lab-06               | On     | xy   | 40862 | 252        | 135        | 0.2384, 0.1803 | 500  | lselect | none   | 66010673         | Yes        |
# | 31 | Dimmable light       | LWB004 | Misc-02              | Off    |      |       |            | 254        |                |      | lselect |        | 66012040         | No         |
# | 32 | Dimmable light       | LWB004 | Misc-03              | Off    |      |       |            | 254        |                |      | none    |        | 66012040         | No         |
# | 33 | Color light          | LST001 | Library-Back         | On     | xy   | 40451 | 207        | 235        | 0.2029, 0.2472 |      | lselect | none   | 66013452         | Yes        |
# | 34 | Color light          | LST001 | TV-Center            | On     | xy   | 41311 | 166        | 161        | 0.2475, 0.2632 |      | none    | none   | 66013452         | Yes        |
# | 35 | Extended color light | LCT002 | Bedroom-Right-Upper  | On     | xy   | 34750 | 205        | 186        | 0.3204, 0.3266 | 164  | none    | none   | 66010673         | Yes        |
# | 36 | Extended color light | LCT002 | Bedroom-Right-Middle | On     | xy   | 38929 | 253        | 237        | 0.2595, 0.2223 | 153  | none    | none   | 66010673         | Yes        |
# | 37 | Extended color light | LCT002 | Bedroom-Right-Lower  | On     | xy   | 39740 | 253        | 234        | 0.2504, 0.2044 | 153  | none    | none   | 66010673         | Yes        |
# +----+----------------------+--------+----------------------+--------+------+-------+------------+------------+----------------+------+---------+--------+------------------+------------+



if [[ $ERROR -ne 0 ]]; then
  echo "ERROR: Had ${ERRORS} test failures."
  exit 1
else
  echo "SUCCESS: No failures."
  echo
  head -n 5 tmp/bridge* tmp/lights* | grep -v -- '------------' | grep -v -E 'INFO|ID'
fi
