#!/bin/bash

for i in *.json; do
  java -jar HueEmulator-SNAPSHOT.jar $i &
done

wait
