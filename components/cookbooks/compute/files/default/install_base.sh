#!/bin/bash
#
# Install ruby and bundle for chef or puppet, oneops user, sshd config
#
set_env()
{
    for ARG in "$@"
    do
      # if arg starts with http then use it to set http_proxy env variable
      if [[ $ARG == http:* ]] ; then
        http_proxy=${ARG/http:/}
        echo "exporting http_proxy=$http_proxy"
        export http_proxy=$http_proxy
      elif [[ $ARG == https:* ]] ; then
        https_proxy=${ARG/https:/}
        echo "exporting https_proxy=$https_proxy"
        export https_proxy=$https_proxy
      elif [[ $ARG == no:* ]] ; then
        no_proxy=${ARG/no:/}
        echo "exporting no_proxy=$no_proxy"
        export no_proxy=$no_proxy
      elif [[ $ARG == rubygems:* ]] ; then
        rubygems_proxy=${ARG/rubygems:/}
        echo "exporting rubygems_proxy=$rubygems_proxy"
        export rubygems_proxy=$rubygems_proxy
      elif [[ $ARG == misc:* ]] ; then
        misc_proxy=${ARG/misc:/}
        echo "exporting misc_proxy=$misc_proxy"
        export misc_proxy=$misc_proxy
      elif [[ $ARG == ruby_binary_path:* ]] ; then
        echo "setting ruby_binary_path to $ARG"
        ruby_binary_path=${ARG/ruby_binary_path:/}
      elif [[ $ARG == ruby_binary_version:* ]] ; then
        echo "setting ruby_binary_version to $ARG"
        ruby_binary_version=${ARG/ruby_binary_version:/}
      fi
    done
}

install_base_centos()
{
  yum -d0 -e0 -y install sudo file make gcc gcc-c++ glibc-devel libgcc libxml2-devel libxslt-devel perl libyaml perl-Digest-MD5 nagios nagios-devel nagios-plugins
  if [ "$major" -lt 7 ] ; then
    yum -d0 -e0 -y install parted
  fi
}

install_ruby_centos()
{
  if [ "$cloud_provider" == "azure" ] && [ "$major" -lt 7 ] && [ ! -n "$ruby_binary_path" ]; then
    echo "Centos 6.x VMs on Azure clouds require Ruby 2.0.0"
    echo "Please add ruby_binary_path env variable in compute cloud service"
    exit 1
  fi

  # installing ruby 2.0.0 from a binary for CentOs 6.x if env variable is there
  if [ "$major" -lt 7 ] && [ -n "$ruby_binary_path" ] ; then
    install_ruby_binary_if_not_installed
  else
    yum -d0 -e0 -y install ruby ruby-libs ruby-devel ruby-rdoc rubygems
  fi
}

install_ruby_binary_if_not_installed()
{
  if ! is_ruby_exists; then
    install_ruby_binary
  else
    ver=`get_ruby_version`
    if [ "$ver" != "$ruby_binary_version" ] ; then
      yum remove -y ruby
      install_ruby_binary
    fi
  fi
}

is_ruby_exists()
{
  ruby -v > /dev/null 2>&1
  if [ "$?" == "0" ]; then
    return 0
  else
    return 1
  fi
}

get_ruby_version()
{
  #this assumes ruby is already installed and returns the currently installed ruby version
  echo `ruby -e 'print "#{RUBY_VERSION}"'`
}

install_ruby_binary()
{
    wget -q -O ruby-binary.tar.gz $ruby_binary_path
    tar zxf ruby-binary.tar.gz --strip-components 1 -C /usr
    rm -f ruby-binary.tar.gz
}

set_gem_source()
{
  proxy_exists=`gem source | grep $rubygems_proxy | wc -l`
  if [ $proxy_exists == 0 ] ; then
    echo "adding $rubygems_proxy to gem sources"
    gem source --add $rubygems_proxy
    remove_source http://rubygems.org/
    remove_source https://rubygems.org/
  fi
}

remove_source()
{
  gem_source="$1"
  default_exists=`gem source | grep $gem_source | wc -l`
  if [ $rubygems_proxy != $gem_source ] && [ $default_exists != 0 ] ; then
    echo "removing $gem_source from source list"
    gem source --remove $gem_source
  fi
}

downgrade_rubygems()
{
  #downgrading rubygems to 1.8.25 because of compatibility issues with rubygems 2.0 and chef 11.4.0
  #https://discourse.chef.io/t/rubygems-format-loaderror/3677/2
  rubygems_ver=$((echo "1.8.26" && gem -v) | sort -V | head -n 1)
  if [ $rubygems_ver == "1.8.26" ]; then
    echo "Downgrading rubygems..."
    gem update --system 1.8.25 --no-ri --no-rdoc --quiet
  fi
}

set_env $@

set -e
if ! [ -e /etc/ssh/ssh_host_dsa_key ] ; then
  echo "generating host ssh keys"
  /usr/bin/ssh-keygen -A
fi

# setup os release variables
echo "Install ruby and bundle."

# sles or opensuse
if [ -e /etc/SuSE-release ] ; then
  zypper -n in sudo rsync file make gcc glibc-devel libgcc ruby ruby-devel rubygems libxml2-devel libxslt-devel perl
  zypper -n in rubygem-yajl-ruby

  # sles
  hostname=`cat /etc/HOSTNAME`
  grep $hostname /etc/hosts
  if [ $? != 0 ]; then
    ip_addr=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d'/' | xargs`
    echo "$ip_addr $hostname" >> /etc/hosts
  fi

# redhat / centos
elif [ -e /etc/redhat-release ] ; then
  release=$(cat /etc/redhat-release | grep -o '[0-9]\.[0-9]')
  major=${release%.*}
  install_base_centos
  install_ruby_centos

  # disable selinux
  if [ -e /selinux/enforce ]; then
    echo 0 >/selinux/enforce
    echo "SELINUX=disabled" >/etc/selinux/config
    echo "SELINUXTYPE=targeted" >>/etc/selinux/config
  fi

  # allow ssh sudo's w/out tty
  grep -v requiretty /etc/sudoers > /etc/sudoers.t
  mv -f /etc/sudoers.t /etc/sudoers
  chmod 440 /etc/sudoers

else
# debian
  export DEBIAN_FRONTEND=noninteractive
  echo "apt-get update ..."
  apt-get update >/dev/null 2>&1
  if [ $? != 0 ]; then
    echo "apt-get update returned non-zero result code. Usually means some repo is returning a 403 Forbidden. Try deleting the compute from providers console and retrying."
    exit 1
  fi
  apt-get install -q -y build-essential make libxml2-dev libxslt-dev libz-dev ruby ruby-dev nagios3

  # seperate rubygems - rackspace 14.04 needs it, aws doesn't
  set +e
  apt-get -y -q install rubygems-integration
  rm -fr /etc/apache2/conf.d/nagios3.conf
  set -e
fi

me=`logname`

set +e

#set gem source from compute env variable
if [ -n "$rubygems_proxy" ]; then
  set_gem_source
else
  rubygems_proxy="https://rubygems.org"
fi
mkdir -p -m 755 /opt/oneops
echo "$rubygems_proxy" > /opt/oneops/rubygems_proxy

if [ -e /etc/redhat-release ] ; then
  downgrade_rubygems
fi

gem_version="1.7.7"
grep 16.04 /etc/issue
if [ $? -eq 0 ]; then
  gem_version="2.0.2"
fi

gem install json --version $gem_version --no-ri --no-rdoc --quiet
if [ $? -ne 0 ]; then
  echo "could not install json gem, version $gem_version"
fi

#set -e
bundler_installed=$(gem list ^bundler$ -i)
if [ $bundler_installed != "true" ]; then
  echo "Installing bundler..."
  ver=$((echo "1.8.25" && gem -v) | sort -V | head -n 1)
  if [ $ver != '1.8.25' ]; then
    gem install bundler -v 1.15.4 --bindir /usr/bin --no-ri --no-rdoc --quiet
  else
    gem install bundler --bindir /usr/bin --no-ri --no-rdoc --quiet
  fi
fi

#set +e
perl -p -i -e 's/ 00:00:00.000000000Z//' /var/lib/gems/*/specifications/*.gemspec 2>/dev/null

# oneops user
grep "^oneops:" /etc/passwd 2>/dev/null
if [ $? != 0 ] ; then
  set -e
  echo "*** ADD oneops USER ***"

  # create oneops user & group - deb systems use addgroup
  if [ -e /etc/lsb-release] ] ; then
    addgroup oneops
  else
    groupadd oneops
  fi

  useradd oneops -g oneops -m -s /bin/bash
  echo "oneops   ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers
else
  echo "oneops user already there..."
fi

set -e

# ssh and components move
if [ "$me" == "oneops" ] ; then
  exit
fi

echo "copying files from provider-setup user $me to oneops..."

home_dir="/home/$me"
if [ "$me" == "root" ] ; then
  cd /root
  home_dir="/root"
else
  cd /home/$me
fi

me_group=$me
if [ -e /etc/SuSE-release ] ; then
  me_group="users"
fi

# Configure gem sources for oneops user
\cp ~/.gemrc /home/oneops/

# gets rid of the 'only use ec2-user' ssh response
sed -e 's/.* ssh-rsa/ssh-rsa/' .ssh/authorized_keys > .ssh/authorized_keys_
mv .ssh/authorized_keys_ .ssh/authorized_keys
chown $me:$me_group .ssh/authorized_keys
chmod 600 .ssh/authorized_keys

# ibm rhel
if [ "$me" != "root" ] ; then
  `rsync -a /home/$me/.ssh /home/oneops/`
else
  `cp -r ~/.ssh /home/oneops/.ssh`
  `cp ~/.ssh/authorized_keys /home/oneops/.ssh/authorized_keys`
fi

if [ "$me" == "idcuser" ] ; then
  echo 0 > /selinux/enforce
  # need to set a password for the rhel 6.3
  openssl rand -base64 12 | passwd oneops --stdin
fi

mkdir -p -m 750 /etc/nagios/conf.d
mkdir -p -m 755 /opt/oneops/workorder
mkdir -p -m 750 /var/log/nagios

# On touch update; chown will break nagios if monitor cookbook does not run.
# Still need to chown a few directories
owner=$( ls -ld /opt/oneops/rubygems_proxy | awk '{print $3}' )
if [ "$owner" == "root" ] ; then
  chown -R oneops:oneops /home/oneops /opt/oneops
  chown -R nagios:nagios /etc/nagios /var/log/nagios /etc/nagios/conf.d
else
  chown -R oneops:oneops /home/oneops/.ssh /opt/oneops/workorder /opt/oneops/rubygems_proxy
fi
