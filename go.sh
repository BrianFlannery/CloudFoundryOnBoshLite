#!/bin/bash

vboxVersionRegExp="^5[.]0[.]16r" ;
vagrantVersion="Vagrant 1.7.4" ;
spiffUrl='https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.7/spiff_darwin_amd64.zip' ;
spiffFile='spiff_darwin_amd64_v1.0.7.zip' ;

die() {
  echo $1 ;
  exit 1 ;
}
cd "$(dirname $0)" || die "Failed to 'cd $(dirname $0)'." ;
thisD=`pwd` ;
source "general.sh" ;

main() {
  execute gem install bosh_cli --no-ri --no-rdoc ;
  check_vagrant ;
  check_vbox ;
  check_boshLite ;
  
  go_bosh_vagrant ;
  
  check_cfRelease ;
  
  install_spiff ;

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
  [[ -e submod/bosh-lite ]] || [[ "$(git submodule status submod/bosh-lite)" ]] \
    || git submodule add git@github.com:cloudfoundry/bosh-lite.git submod/bosh-lite ;
  [[ -e submod/bosh-lite ]] || die "ERROR: Failed to find bosh-lite submodule." ;
}
go_bosh_vagrant() {
  execute cd submod/bosh-lite ;
  execute vagrant up --provider=virtualbox ;
  execute bosh target 192.168.50.4 lite ;
  local testForRoute=`netstat -nr | egrep '^10[.]244[\/]16' | awk '{print $2}'` ;
  [[ "192.168.50.4" == "$testForRoute" ]] || execute bin/add-route ;
  execute cd ../.. ;
}
check_cfRelease() {
  [[ -e submod ]] || mkdir submod ;
  [[ -e submod/cf-release ]] || git submodule update ;
  [[ -e submod/cf-release ]] || [[ "$(git submodule status submod/cf-release)" ]] \
    || git submodule add git@github.com:cloudfoundry/cf-release.git submod/cf-release ;
  [[ -e submod/cf-release ]] || die "ERROR: Failed to find cf-release submodule." ;
}
install_spiff() {
  [[ -d $thisD/bin ]] || mkdir $thisD/bin ;
  local testPath=`echo "$PATH" | perl -ne "m{\\Q$thisD/bin\\E} && print \$_" ` ;
  [[ $testPath ]] || export PATH="$PATH:$thisD/bin" ;
  local testForSpiff=`which spiff` ;
  if [[ -z $testForSpiff ]] ; then
    [[ ! -e $thisD/bin/spiff ]] || die "ERROR: $thisD/bin is in the \$PATH and contains spiff - but spiff is not found via 'which spiff'." ;
    [[ -e $spiffFile ]] || wget -qO $spiffFile $spiffUrl 2> /dev/null || curl -s $spiffUrl > $spiffFile ;
    tmpd=`mktemp -d "${TMPDIR:-/tmp}/tmp.d.XXXXXXXXXX"` ;
    ( execute cd $tmpd ;
      unzip $thisD/$spiffFile ;
      execute mv spiff $thisD/bin/ ;
    )
  fi ;
}
go_deploy_cf() {
  execute cd submod/bosh-lite ;
  local f=latest-bosh-lite-stemcell-warden.tgz ;
  if [[ -f $f ]] ; then
    [[ ! -e ../../$f ]] || execute rm ../../$f ;
    execute mv $f ../../ ;
    ln -s ../../$f $f ;
  fi ;
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
