#!/bin/bash
dpkg-deb -Zgzip -b deb
VERSION=`dpkg-deb -f deb.deb Version`
mv deb.deb com.clayfreeman.stash-cmds_${VERSION}.deb
