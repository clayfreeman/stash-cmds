#!/bin/bash
dpkg-deb -b deb -Zgzip
VERSION=`dpkg-deb -f deb.deb Version`
mv deb.deb com.clayfreeman.stash-cmds_${VERSION}.deb