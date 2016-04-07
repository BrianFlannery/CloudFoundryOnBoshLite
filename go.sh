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
  
  go_bosh_vagrant ;
  
  check_cfRelease ;

  go_deploy_cf ;
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
  [[ -e submod ]] || mkdir submod ;
  [[ -e submod/bosh-lite ]] || git submodule update ;
  [[ -e submod/bosh-lite ]] || die "ERROR: Failed to find bosh-lite submodule." ;
}
go_bosh_vagrant() {
  execute cd submod/bosh-lite ;
  execute vagrant up --provider=virtualbox ;
  execute bosh target 192.168.50.4 lite ;
  execute bin/add-route ;
  execute cd ../.. ;
}
check_cfRelease() {
  [[ -e submod ]] || mkdir submod ;
  [[ -e submod/cf-release ]] || git submodule update ;
  [[ -e submod/cf-release ]] || die "ERROR: Failed to find cf-release submodule." ;
}
go_deploy_cf() {
  execute cd submod/bosh-lite ;
  local f=latest-bosh-lite-stemcell-warden.tgz ;
  if [[ ! -e $f ]] ; then
    for path in .. ../.. ; do
      if [[ -e $path/$f ]] ; then
        ln -s $path/$f $f ;
        break ;
      fi ;
    done ;
  fi ;
  execute bin/provision_cf ;
  
  # # # Dies with this conclusion:
    # Generating bosh lite manifest from /Users/bflannery/dw/github/cf/CloudFoundryOnBoshLite/submod/cf-release/scripts/generate-bosh-lite-dev-manifest
    # Aborted. Please install spiff by following https://github.com/cloudfoundry-incubator/spiff#installation
    # ERROR: From command bin/provision_cf: '1'.
  # TODO FIXME XXX

  execute cd ../.. ;
}

main ;

#
