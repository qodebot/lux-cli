#!/usr/bin/env bash
#-------------------------------------------------------------------------------
#===============================================================================

    red=$(tput setaf 1)
    red2=$(tput setaf 9)
    yellow=$(tput setaf 11)
    orange=$(tput setaf 214)
    green=$(tput setaf 2)
    blue=$(tput setaf 12)
    cyan=$(tput setaf 123)
    purple=$(tput setaf 213)
    grey=$(tput setaf 244)
    grey2=$(tput setaf 240)
    w=$(tput setaf 15)
    wz=$(tput setaf 248)
    lambda="\xCE\xBB"
    line="$(sed -n '2,2 p' $BASH_SOURCE)$nl"
    bline="$(sed -n '3,3 p' $BASH_SOURCE)$nl"
    x=$(tput sgr0)
    sp="   "
    tab=$'\t'
    nl=$'\n'
    diamond='\xE1\x9B\x9C'
    delim='\x01'
    delta="${orange}\xE2\x96\xB3"
    pass="${green}\xE2\x9C\x93"
    fail="${red}\xE2\x9C\x97$red2"
    dots='\xE2\x80\xA6'
    space='\x20'

    eol="$(tput el)"
    eos="$(tput ed)"
    cll="$(tput cuu 1 && tput el)"
    bld="$(tput bold)"
    rvm="$(tput rev)"

#-------------------------------------------------------------------------------
# Init Vars
#-------------------------------------------------------------------------------

    opt_quiet=1
    opt_force=1
    opt_verbose=1
    opt_debug=1
    opt_basis=
    opt_dump_col="$orange"

    [[ "${@}" =~ "--debug" ]] && opt_debug=0 || :
    [[ "${@}" =~ "--info"  ]] && opt_verbose=0 || :
    [[ "${@}" =~ "--quiet" ]] && opt_quiet=0 || :
    [[ "${@}" =~ "--force" ]] && opt_force=0 || :

    __buf_list=1
#-------------------------------------------------------------------------------
# Sig / Flow
#-------------------------------------------------------------------------------

    function handle_sigint(){ s="$?"; kill 0; exit $s;  }
    function handle_sigtstp(){ kill -s SIGSTOP $$; }
    function handle_input(){ [ -t 0 ] && stty -echo -icanon time 0 min 0; }
    function cleanup(){ [ -t 0 ] && stty sane; }
    function fin(){
      local E="$?"
      cleanup
      #[ $opt_force -eq 0 ] && lux_usage || echo "$opt_force"
      [ $E -eq 0 ] && __print "${pass} ${green}${1:-Done}.${x}\n\n" \
                   || __print "$red$fail ${1:-${err:-Cancelled}}.${x}\n\n"
    }

#-------------------------------------------------------------------------------
# Traps
#-------------------------------------------------------------------------------

    trap handle_sigint INT
    trap handle_sigtstp SIGTSTP
    trap handle_input CONT
    trap fin EXIT

#-------------------------------------------------------------------------------
# Printers
#-------------------------------------------------------------------------------

    function __print(){
      local text color prefix
      text=${1:-}; color=${2:-grey}; prefix=${!3:-};
      [ $opt_quiet -eq 1 ] && [ -n "$text" ] && printf "${prefix}${!color}%b${x}\n" "${text}" 1>&2 || :
    }

    function    info(){ local text=${1:-}; [ $opt_verbose -eq 0 ] || [ $opt_debug -eq 0 ]  && __print "$lambda$text" "blue"; }
    function   silly(){ local text=${1:-}; [ $opt_verbose -eq 0 ] && __print "$dots$text" "purple"; }
    function   trace(){ local text=${1:-}; [ $opt_verbose -eq 0 ] && __print "$text" "grey2"; }
    function  ftrace(){ local text=${1:-}; [ $opt_verbose -eq 0 ] && __print " $text" "fail"; }
    function  ptrace(){ local text=${1:-}; [ $opt_verbose -eq 0 ] && __print " $text$x" "pass"; }
    function   error(){ local text=${1:-}; __print " $text" "fail"; }
    function    warn(){ local text=${1:-}; __print " $text$x" "delta";  }
    function    pass(){ local text=${1:-}; __print " $text$x" "pass"; }
    function success(){ local text=${1:-}; __print "\n$pass $1 [$2] \n$bline\n\n\n"; }
    function   fatal(){ trap - EXIT; __print "\n$fail $1 [$2] \n$bline\n\n\n"; exit 1; }
    function   quiet(){ [ -t 1 ] && opt_quiet=${1:-1} || opt_quiet=1; }
    function  status(){
      local ret res msg
      ret=$1; res=$2; msg=$3; __print "$res";
      [ $ret -eq 1 ] && fatal "Error: $msg, exiting" "1";
      return 0
    }

  function confirm() {
    local ret;ret=1
    printf "${1:-Are you sure ?}"
    while read -r -n 1 -s answer; do
      if [[ $answer = [YyNn10tf+\-q] ]]; then
        [[ $answer = [Yyt1+] ]] && printf "${bld}${green}yes${x}" && ret=0 || :
        [[ $answer = [Nnf0\-] ]] && printf "${bld}${red}no${x}" && ret=1 || :
        [[ $answer = [q] ]] && printf "\n" && exit 1 || :
        break
      fi
    done
    printf "\n"
    return $ret
  }


  function dump(){
    local len arr i this flag newl
    arr=("${@}"); len=${#arr[@]}
    [ $__buf_list -eq 0 ] && flag="\r" &&  newl="$eol" || newl="\n"
    if [ $len -gt 0 ]; then
      handle_input
      for i in ${!arr[@]}; do
        this="${arr[$i]}"
        [ -n "$this" ] && printf "$flag$opt_dump_col$dots(%02d of %02d) $this $x$newl" "$i" "$len"
        sleep 0.1
      done
      cleanup
      printf "$flag$green$pass (%02d of %02d) Read. $x$eol\n" "$len" "$len"
    fi
  }

  #__print "$BASH_SOURCE from term $DIR yay $(dirname ${BASH_SOURCE[1]} && pwd) ||"
