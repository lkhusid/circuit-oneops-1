#!/bin/bash
echo "downloading base gems"
/opt/chef/embedded/bin/gem install aws-s3 -v 0.6.3 --conservative
/opt/chef/embedded/bin/gem install parallel -v 1.11.2 --conservative
/opt/chef/embedded/bin/gem install i18n -v 0.6.9 --conservative
/opt/chef/embedded/bin/gem install activesupport -v 3.2.11 --conservative
echo "Done"

echo "install git and dependencies"
sudo yum install libgnome-keyring -y
sudo yum install perl-Error -y
sudo yum isntall perl-Git -y
sudo yum install perl-TermReadKey -y
sudo yum install git -y
echo "Done"