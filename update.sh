#!/bin/bash
dpkg-scanpackages deb override 2> /dev/null | tee Packages | \
  gzip -9c > Packages.gz
