#!/bin/bash

vboxVersionRegExp="^5[.]0[.]16r" ;
vagrantVersion="Vagrant 1.7.4" ;

cd "$(dirname $0)" || error="Failed to 'cd $(dirname $0)'.";
if [[ $error ]] ; then
  echo "$error" ;
  exit 1 ;
fi ;
source "general.sh" ;

main() {
  execute gem install bosh_cli --no-ri --no-rdoc ;
  check_vagrant ;
  check_vbox ;
  check_boshLite ;
}

check_vagrant(){
  local thisV=`vagrant --version` ;
  [[ "$vagrantVersion" == "$thisV" ]] \
    || echo "WARNING: wrong Vagrant version ('$thisV' should be '$vagrantVersion')." 1>&2 ;
  #
}
check_vbox(){
  local thisV=`VBoxManage --version` ;
  local diff=`echo "$thisV" | egrep -v $vboxVersionRegExp` ;
  [[ -z $diff ]] \
    || echo "WARNING: wrong VirtualBox version ('$thisV' should be '$vboxVersionRegExp'~ish (diff was '$diff'))." 1>&2 ;
  #
}
check_boshLite() {
  [[ -e submod ]]
}

main ;

#
