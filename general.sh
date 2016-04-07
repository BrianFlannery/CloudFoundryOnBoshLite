# # # Partial copy of general.sh from https://gitlab.devops.geointservices.io/DevOps/Helpers
# # # v. 3d12ac1f

die() {
  echo "$@" 1>&2 ;
  exit 1 ;
}
execute() {
  [[ -z $VERBOSE ]] || VERBOSE='false' ;
  local e='' ;
  if [[ "" == "$VERBOSE" || "false" == "$VERBOSE" ]] ; then
    _execute "$@" || e=$? ;
  else
    vexecute "$@" || e=$? ;
  fi ;
  ( exit $e ) ;
}
  _execute() {
    cmdX="$@" ;
    "$@" ;
    local _error=$? ;
    if [[ -z $_error || "$_error" == "" || "$_error" == "0" ]] ; then
      true ;
    else
      echo "ERROR: From command $cmdX: '$_error'." 1>&2 ;
      exit $_error ;
    fi ;
  }
  vexecute() {
    cmdX="$@" ;
    local verr='' ;
    echo "NOTE: Executing q($cmdX)." 1>&2 ;
    _execute "$@" || verr=$? ;
    echo ;
    ( exit $verr ) ;
  }
#

#
