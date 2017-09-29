#!/bin/bash

#set to use proxy for yum and chef embedded gem
useProxy=false

#custom repos for gems and yum.
yumRepoBase=http://myrepos.example.com/base/centos/7.2/os/
yumRepoExtras=http://myrepos.example.com/base/centos/7.2/extras/
yumRepoUpdates=http://myrepos.example.com/base/centos/7.2/updates/

#these two have to match
yumConfigRepo=http://myrepos.example.com/epel/7/
yumConfigRepoPath=/etc/yum.repos.d/repos.example.com_epel_7_.repo

gemRepo="http://mysourcerepos.example.com/gemstuff/"

#user set in .kitchen.yml. default is vagrant
kitchenUser=vagrant

if [ "$useProxy" = true ] ; then
    echo "setting up proxy"
    sudo yum clean all
    echo "setting yum to use proxy"
    echo "removing default repos from yum"
    sudo rm -rf /etc/yum.repos.d/*
    echo "adding custom repo to yum"
    echo "[base]" > /etc/yum.repos.d/base.repo
    echo name=base >> /etc/yum.repos.d/base.repo
    echo baseurl=$yumRepoBase >> /etc/yum.repos.d/base.repo
    echo enabled=1 >> /etc/yum.repos.d/base.repo
    echo gpgcheck=0 >> /etc/yum.repos.d/base.repo
    echo "[extras]" > /etc/yum.repos.d/extras.repo
    echo name=extras >> /etc/yum.repos.d/extras.repo
    echo baseurl=$yumRepoExtras >> /etc/yum.repos.d/extras.repo
    echo enabled=1 >> /etc/yum.repos.d/extras.repo
    echo gpgcheck=0 >> /etc/yum.repos.d/extras.repo
    echo "[updates]" > /etc/yum.repos.d/updates.repo
    echo name=updates >> /etc/yum.repos.d/updates.repo
    echo baseurl=$yumRepoUpdates >> /etc/yum.repos.d/updates.repo
    echo enabled=1 >> /etc/yum.repos.d/updates.repo
    echo gpgcheck=0 >> /etc/yum.repos.d/updates.repo
    yum -d0 -e0 -y install rsync yum-utils
    yum-config-manager --add-repo $yumConfigRepo
    echo gpgcheck=0 >> $yumConfigRepoPath
    yum -q makecache

    echo "setting url for internal gem repo"
    sudo /opt/chef/embedded/bin/gem sources --add $gemRepo
    sudo /opt/chef/embedded/bin/gem sources -r https://rubygems.org/
    sudo runuser -l $kitchenUser -c "/opt/chef/embedded/bin/gem sources --add $gemRepo"
    sudo runuser -l $kitchenUser -c "/opt/chef/embedded/bin/gem sources -r https://rubygems.org/"
fi
echo "installing base yum packages"
yum -d0 -e0 -y install sudo file make gcc gcc-c++ glibc-devel libgcc ruby ruby-libs ruby-devel libxml2-devel libxslt-devel ruby-rdoc rubygems perl perl-Digest-MD5 nagios nagios-devel nagios-plugins
echo "downloading base gems"
sudo /opt/chef/embedded/bin/gem env gemdir
sudo /opt/chef/embedded/bin/gem install aws-s3 -v 0.6.3 --conservative
sudo /opt/chef/embedded/bin/gem install parallel -v 1.9.0 --conservative
sudo /opt/chef/embedded/bin/gem install i18n -v 0.6.9 --conservative
sudo /opt/chef/embedded/bin/gem install activesupport -v 3.2.11 --conservative
echo "Done"


