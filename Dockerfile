#Copyright 2016 Juniper Networks, Inc. All rights reserved.
#
#Licensed under the Juniper Networks Script Software License (the "License"). 
#
#You may not use this script file except in compliance with the License, which is located at 
#
#http://www.juniper.net/support/legal/scriptlicense/
#
#Unless required by applicable law or otherwise agreed to in writing by the parties, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.


from ubuntu:14.04
MAINTAINER Iddo Cohen <icohen@juniper.net>

# Editing sources and update apt.
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe multiverse restricted" > /etc/apt/sources.list && \
  echo "deb http://archive.ubuntu.com/ubuntu trusty-security main universe multiverse restricted" >> /etc/apt/sources.list && \
  apt-get update && \
  apt-get upgrade -y -o DPkg::Options::=--force-confold

# Packages for SaltStack installation
RUN apt-get install -y \
  git \
  git-core \
  wget \
  python-dev \
  python-pip

# (Optional) Packages for myself
RUN apt-get install -y \
   openssh-server \
   locate \
   vim

# Packages for PyEZ installation #1
RUN apt-get install -y \
   libssl-dev \
   libxslt1-dev \
   libxml2-dev \
   libxslt-dev


### Packages for PyEZ installation #2
###
# Installing older version of libffi6 so libffi-dev can be installed
###
RUN apt-get install -y --force-yes \
   libffi6=3.1~rc1+r3.0.13-12 \
   libffi-dev

### Packages for 64bit systems
###
# For 64bit systems one gets "usr/bin/ld: cannot find -lz" at PyEZ installation, solution install lib32z1-dev and zlib1g-dev
# Note: Because sh -c is executed via Docker, it is not == but =
###
RUN if [ "$(uname -m)" = "x86_64" ]; then apt-get install -y lib32z1-dev zlib1g-dev; fi

# Installing PyEZ and jxmlease for SaltStack salt-proxy
RUN pip install junos-eznc jxmlease

### Retrieving bootstrap.sh form SaltStack
###
# Installation manager for SaltStack.
###
RUN wget -O /root/install_salt.sh http://bootstrap.saltstack.org

### Installing SaltStack (carbon release).
###
# Carbon release to avoid grains/facts bugs with __proxy__.
#
#-M Install master, -d ignore install check, -X do not start the deamons and -P allows pip installation of some packages.
#
###
RUN sh /root/install_salt.sh -d -M -X -P git carbon

### Creating directories for SaltStack
RUN mkdir -p /srv/salt /srv/pillar

### Replacing salt-minion configuration
RUN sed -i 's/^#master: salt/master: localhost/;s/^#id:/id: minion/' /etc/salt/minion

### Replacing salt-proxy configuration
RUN if [ -f /etc/salt/proxy ]; then sed -i 's/^#master: salt/master: localhost/' /etc/salt/proxy; else echo "master: localhost\nmultiprocessing: False\n" > /etc/salt/proxy; fi

COPY docker/salt_proxy.yaml /etc/salt/proxy

#Slim the container a litte.
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
