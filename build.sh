#!/bin/bash
find . -type f -name ".DS_Store" -exec rm -f "{}" \;
dpkg-deb -Zgzip -b deb
VERSION=`dpkg-deb -f deb.deb Version`
mv deb.deb com.clayfreeman.stash-cmds_${VERSION}.deb
