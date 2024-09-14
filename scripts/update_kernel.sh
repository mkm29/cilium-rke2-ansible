#!/usr/bin/env bash

rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
dnf install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm -y
dnf --enablerepo=elrepo-kernel install kernel-ml -y
grubby --default-kernel