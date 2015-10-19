#!/bin/bash
dpkg-deb -b deb
VERSION=`dpkg-deb -f deb/com.clayfreeman.stash-cmds_1.0-2.deb Version`
mv deb.deb com.clayfreeman.stash-cmds_${VERSION}.deb
