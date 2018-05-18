#!/usr/bin/env bash

set -e
if ! [ -e /etc/ssh/ssh_host_dsa_key ] ; then
  echo "generating host ssh keys"
  /usr/bin/ssh-keygen -A
fi

# User setup
me=`logname`
home_dir="/home/$me"

if [ "$me" == "root" ] ; then
  cd /root
  home_dir="/root"
else
  cd /home/$me
fi
me_group=$me


# This has something to do with deployment time reporting
set +e
perl -p -i -e 's/ 00:00:00.000000000Z//' /var/lib/gems/*/specifications/*.gemspec 2>/dev/null
set -e

# Setup ssh
sed -e 's/.* ssh-rsa/ssh-rsa/' .ssh/authorized_keys > .ssh/authorized_keys_
mv .ssh/authorized_keys_ .ssh/authorized_keys
chown $me:$me_group .ssh/authorized_keys
chmod 600 .ssh/authorized_keys

if [ "$me" != "root" ] ; then
  `rsync -a /home/$me/.ssh /home/oneops/`
else
  `cp -r ~/.ssh /home/oneops/.ssh`
  `cp ~/.ssh/authorized_keys /home/oneops/.ssh/authorized_keys`
fi

chown -R oneops:oneops /home/oneops/.ssh /opt/oneops/workorder /opt/oneops/rubygems_proxy

# Setup path
if [ -e /home/oneops/ruby/2.0.0-p648/bin ]; then
    echo "export PATH=/home/oneops/ruby/2.0.0-p648/bin:$PATH" >> /home/oneops/.bash_profile
    echo "export GEM_HOME=/home/oneops/ruby/2.0.0-p648/lib/ruby/gems/2.0.0" >> /home/oneops/.bash_profile
    echo "export GEM_PATH=/home/oneops/ruby/2.0.0-p648/lib/ruby/gems/2.0.0" >> /home/oneops/.bash_profile
fi