#!/usr/bin/env bash

	status_err=()
	err_vals=()
	status_pass=()
	pass_vals=()

	state_config=()  #STATE_CONFIG_READY
	state_install=() #STATE_INSTALL_READY
	state_build=()   #STATE_BUILD_READY
	state_publish=() #STATE_PUBLISH_READY

#-------------------------------------------------------------------------------
# STAT UTILS
#-------------------------------------------------------------------------------

function is_error(){
	[ -z "$1" ] && return 1 || :
	res=$(in_array "$1" "${status_err[@]}");ret=$?
	#info "iserror ($1) ($ret) [${status_err[*]}]?"
	return $ret
}

function unstat(){
	local val="-$1"; shift;
	local list=(${status_err[@]})
	#wtrace "Unsetting status [$val]"
	val=$(upd_array "$val" "${list[@]}")
	status_err=($val)
}

function dump_results(){

	trace "$bline"

	opt_dump_col="$orange"
	dump "${status_err[@]}"

	opt_dump_col="$purple"
	dump "${err_vals[@]}"

	trace "$bline"

	opt_dump_col="$blue"
	dump "${status_pass[@]}"

	opt_dump_col="$cyan"
	dump "${pass_vals[@]}"
}


#-------------------------------------------------------------------------------
# STATE UTILS
#-------------------------------------------------------------------------------

function __env_repair(){
	trace "---env_repair"
	local arr=(${@})
	local len=${#arr[@]}
	if [ $len -gt 0 ]; then
		for i in ${!arr[@]}; do
			local this="${arr[$i]}"
			#check if function exists
			declare -F "${!this}" &> /dev/null
			ret=$?
			if [ $ret -eq 0 ]; then
				${!this};
				ret=$?
				sleep .02
				log "$(res $ret) Fixed ($this)?"
			else
			 log "$(res $ret) No FX for ($this)"
			fi
		done
	fi
	return 0
}

#-------------------------------------------------------------------------------
# CHECKUPS
#-------------------------------------------------------------------------------

function lux_full_repair(){
	lux_checkup
	silly "Lux Repairing..."
	lux_pre_config
	lux_pre_config_cli
	lux_pre_config_bash_prof

	lux_pre_config_lux_home
	#repair_home "$LUX_HOME" #only set with rc
	#lux_make_rc

	lux_pre_config_rc_file #attempt to make rc file if it doesnt exist
	lux_pre_config_bin_dir
	lux_pre_install
	lux_make_rc
}

function lux_auto_repair(){
	lux_pre_config_cli
	lux_pre_config_lux_home
	#repair_home "$LUX_HOME" #only set with rc
	lux_pre_config_rc_file
	lux_pre_config_bin_dir
}

function lux_checkup(){

	silly "Check Setup!"

	unset status_err
	unset err_vals

	unset status_pass
	unset pass_vals

	#check if this dir is in PATH
	#echo $BIN_DIR $THIS_DIR

	#lux_auto_repair
	check_each_state
	#dump_results
}

function check_each_state(){

	#[ -z "$BIN_DIR" ] && status+=( ERR_DBIN_UNDEF )  || status_pass+=( DBIN_DEF )
	status_err=()
	err_vals=()

	status_pass=()
	pass_vals=()


	assert_defined  BIN_DIR        STATE_DBIN_DEF       ;
	assert_inpath   BIN_DIR			   STATE_DBIN_PATH			;


	assert_defined  BASH_PROFILE   STATE_BASH_PROF_DEF  ;
	assert_defined  BASH_RC        STATE_BASH_RC_DEF    ;



	assert_defined  LUX_RC         STATE_LUX_RC_DEF     ;
	assert_file     LUX_RC         STATE_LUX_RC_FILE    ;

	assert_defined  LUX_BUILD      STATE_LUX_BUILD_DEF  ;
	assert_defined  LUX_DIST   	   STATE_LUX_DIST_DEF   ;

	assert_defined  LUX_SEARCH_PATH  STATE_LUX_SRC_DEF  ;
	# ERR_LUX_RCLINK_MISSING
	assert_defined  LUX_HOME  		 STATE_LUX_HOME_DEF   ;

	assert_defined  LUX_CLI        STATE_LUX_CLI_DEF    ;
	assert_dir      LUX_CLI        STATE_LUX_CLI_DEF    ;

	assert_defined  BASH_USR_BIN    STATE_BASH_UBIN_DEF ;
	assert_inpath   BASH_USR_BIN    STATE_BASH_UBIN_PATH;
	assert_dir      BASH_USR_BIN    STATE_BASH_UBIN_DIR ;

	assert_defined  LUX_INSTALL_DIR  STATE_LUX_INST_DEF ;
	assert_writable LUX_INSTALL_DIR  STATE_LUX_INST_WRITE;
	#LUX_CLI_INSALL_PATH
}


#-------------------------------------------------------------------------------
# ASSERTIONS
#-------------------------------------------------------------------------------

function record_assertion(){
	local ret val st this name
	res=$1;this=${!2}; st=$3; val="$4" name=$2;
	[ $res -eq 1 ] && { status_err+=( "$st" ); err_vals+=( "$name" ); } ||
										{ status_pass+=( "$st" ); pass_vals+=( "$name:${4:-$this}" ); }

	[ $res -eq 0 ] && trace "${pass}Passed$x | $st ${tab} |  $grey$this$x "    ||:
	[ $res -eq 1 ] && trace "${fail}Failed$x | $st ${tab} |  $grey2${name}$x " ||:
}

function assert_defined(){
	local ret this; this=${!1};
	[ -z "$this" ] && ret=1 || ret=0; record_assertion $ret "$1" "$2"
	#silly "VAR check ($1)=> $this [$ret]"
	return $ret
}

function assert_file(){
	local ret this; this=${!1};
	[ ! -f "$this" ] && ret=1 || ret=0; record_assertion $ret "$1" "$2" true
	return $ret
}

function assert_dir(){
	local ret this; this=${!1};
	if [ -n "$this" ]; then
	 [ ! -d "$this" ] && ret=1 || ret=0;
	else
		ret=1
	fi
	record_assertion $ret "$1" "$2" true
	#silly "DIR check ($1)=> $this [$ret]"
	return $ret
}

function assert_inpath(){
	local ret this; this=${!1};
	if [ -n "$this" ]; then
	 [[ ! "$PATH" =~ "$this" ]] && ret=1 || ret=0;
	else
		ret=1
	fi
	record_assertion $ret "$1" "$2" true
	#silly "PATH check ($1)=> $this [$ret]"
	return $ret
}

function assert_writable(){
	local ret this; this=${!1};
	if [ -n "$this" ]; then
	 [ -w "$this" ] && ret=1 || ret=0;
	else
		ret=1
	fi
	record_assertion $ret "$1" "$2" true
	#silly "WRITE check ($1)=> $this [$ret]"
	return $ret
}

function assert_infile(){
	local this=$1
	:
}

function assert_ready(){
	local this=$1
	:
}
#STATE_LUX_CONFIG_READY

#STATE_LUX_RC_CREATED

#STATE_LUX_RC_LINK

#STATE_LUX_USER_MODE

#STATE_LUX_USER_BUILD

#STATE_LUX_DEV_MODE

#STATE_LUX_DEV_DEPLOY

#STATE_LUX_UNINSTALL


#-------------------------------------------------------------------------------
# PROMPTS
#-------------------------------------------------------------------------------


	function repair_home(){
		LUX_HOME="$1"
		lux_pre_config_set_homevars
		[ -d "$LUX_HOME" ] && unstat STATE_LUX_HOME_DEF || :
		ptrace "Repaired LUX Home ($LUX_HOME)"
	}

	function repair_binvars(){
		trace "try Resolve STATE_BASH_UBIN_DEF-(Sub Dirs)"
		BASH_USR_BIN="$1"
		if [ -n "$BASH_USR_BIN" ]; then
			QODEPARTY_INSTALL_DIR="$BASH_USR_BIN/qodeparty"
			LUX_INSTALL_DIR="$QODEPARTY_INSTALL_DIR/lux"
		else
			: #printf "Lux home not defined $LUX_HOME \n"
		fi
		ptrace "Repaired Bin Vars ($BASH_USR_BIN)"
	}


	function prompt_home(){
		if confirm "${lambda} ${blue}LUX_HOME$x is not set. Set the location manually (y/n)"; then
			res=$(prompt_path "Where is \${blue}LUX_HOME\$x directory on \$blue\$HOSTNAME\$x" "Is this correct" "$LUX_HOME");ret=$?
			#[ $ret -eq 1 ] && return 1;
		else
			:
		fi
	}


	function prompt_repos(){
		local res ret next
		if [ -z "$LUX_SEARCH_PATH" ]; then
			wtrace "Lux search path missing${x}"

			if confirm "${x}Do you want to run repo finder (y/n)"; then
				#reset_user_data
				  sleep 0.2
					#clear
					res=$(prompt_path "Where should Lux search for Repos ex: \$blue\$default\$x" "Search for Lux repos in" "$HOME/src");ret=$?
					[ $ret -eq 1 ] && return 1;

					lux_need_align_repos;ret=$?

					if [ $ret -eq 0 ]; then
							if [ -d "$res" ]; then
								pass "Found search path $res" #"$ret"
								lux_find_repos "$res"; ret=$?
								[ $ret -eq 0 ] && LUX_SEARCH_PATH="$res" || :
								#silly "Search path was $res $LUX_SEARCH_PATH"
								lux_align_repos;

							else
							  fatal "Unable to find search path -> $res"
							fi
					fi

				return 0
			else
				return 1
			fi
		fi
		return 0
	}


#-------------------------------------------------------------------------------
# REPAIR
#-------------------------------------------------------------------------------


	function lux_pre_config(){
		trace "try Resolve STATE_DBIN_PATH"
		if is_error STATE_DBIN_PATH; then
			warn "Please run config again!"
			#fatal requires user step
		else
			: #pptrace "found DEV_BIN"
		fi
	}


	function lux_pre_config_cli(){
		trace "try Resolve STATE_LUX_CLI_DEF"
		if is_error STATE_LUX_CLI_DEF; then

			if [ -n "$LUX_CONFIG_HOME" ]; then
				LUX_CLI="$LUX_CONFIG_HOME"
				unstat STATE_LUX_CLI_DEF
			fi

		else
			: #pptrace "found CLI_DEF ($LUX_CONFIG_HOME)"
			#fatal requires user step
		fi
	}

	function lux_pre_config_bash_prof(){
		trace "try Resolve STATE_BASH_PROF_DEF"
		if is_error STATE_BASH_PROF_DEF; then
			warn "Prompt User for PROFILE or RC"
			#fatal requires user step
		else
			: #pptrace "found BASH_PROFILE ($BASH_PROFILE)"
		fi
	}



	function lux_pre_config_lux_home(){
		trace "try Resolve STATE_LUX_HOME_DEF"

		if is_error STATE_LUX_HOME_DEF; then

			if [ -n "$LUX_CSS" ]; then
				LUX_HOME="$LUX_CSS"

			else

				if [ $opt_skip_input -eq 1 ]; then
					#REQUIRES USER INPUT
					prompt_repos "$LUX_HOME";ret=$?

					if [ -d "$LUX_HOME" ]; then
						repair_home "$LUX_HOME"
					else
						wtrace "Cant find Lux Home"
						lux_make_rc
					fi

					[ $ret -eq 0 ] && unstat STATE_LUX_SRC_DEF || :
				else
					:
					#RECORD USER INPUT NEED
				fi

			fi

			if [ -n "$LUX_HOME" ]; then
				repair_home "$LUX_HOME"
			fi

			#fatal requires user step
		else
			ptrace "found LUX Home ($LUX_HOME)"
		fi
	}

	function lux_pre_config_rc_file(){
		trace "try Resolve STATE_LUX_RC_FILE"
		if is_error STATE_LUX_RC_FILE; then
			warn "RC Files requires PROFILE"
			#Do you want to make RC FIle?
			lux_make_rc 1
			#fatal requires user step
		else
			: #pptrace "found LUX_RC"
		fi
	}





	function lux_pre_config_set_homevars(){
		trace "try Resolve STATE_LUX_BUILD_DEF"
		trace "try Resolve STATE_LUX_DIST_DEF"
		if [ -n "$LUX_HOME" ]; then

			THIS_ROOT="$(dirname $LUX_HOME)"

			LUX_BUILD="$LUX_HOME/build"
			LUX_DIST="$LUX_HOME/dist"
			LUX_RES="$LUX_HOME/www/res"
			LUX_RBUILD="$LUX_RES/build"
			LUX_INST=1

			LUX_LIB="$LUX_HOME/src/lib"
			LUX_EXT="$LUX_LIB/ext"
			LUX_DEFS="$LUX_LIB/defs"

			LUX_CORE="$LUX_HOME/src/styl/lux"
			LUX_VARS="$LUX_HOME/src/styl/vars"
			LUX_UTIL="$LUX_HOME/src/styl/util"

			OPT_INCLUDE="--include $LUX_EXT --include $LUX_UTIL --include $LUX_VARS --include $LUX_CORE"
			OPT_IMPORT="--import $LUX_UTIL --import $LUX_VARS " #order matters
			OPT_USE="" #update with lux_var_refresh
			OPT_ALL="" #update with lux_var_refresh

			#------
			unstat STATE_LUX_BUILD_DEF
			unstat STATE_LUX_DIST_DEF
		else
			: #printf "Lux home not defined $LUX_HOME \n"
		fi
	}



	function lux_pre_config_bin_dir(){
		trace "try Resolve STATE_BASH_UBIN_DEF"

		if is_error STATE_BASH_UBIN_DEF; then

			vars=( BASH_USR_BIN MY_BIN HOME_BIN USR_BIN QODE_BIN BIN)
			for this in ${vars[@]}; do
				#info "TRY $this => ${!this}"
				if [ -n "${!this}" ]; then
				  BASH_USR_BIN="${!this}"
				  break;
				fi
			done

			#prompt or create bin
			#if [ $opt_skip_input -eq 1 ]; then
			if [ -z "$BASH_USR_BIN" ]; then
				res=$(prompt_path "Cant find a default BIN directory var. What bin path to use (ex:\$HOME/bin) " "Set your home bin to")
				BASH_USR_BIN="$res"
				repair_binvars "$BASH_USR_BIN"
			fi

			unstat STATE_BASH_UBIN_DEF

		else
			: #ptrace "found BASH_USR_BIN ($BASH_USR_BIN) ??"
		fi


		trace "try Resolve STATE_BASH_UBIN_PATH"
		if is_error STATE_BASH_UBIN_PATH; then
			wtrace "PATH missing home bin, create rc file or set env var"
		else
			: #ptrace "# Not implemented (STATE_BASH_UBIN_PATH)"
		fi

		trace "try Resolve STATE_BASH_UBIN_DIR"
		if is_error STATE_BASH_UBIN_DIR; then
			[ ! -d "$BASH_USR_BIN" ] && mkdir -P "$BASH_USR_BIN" || :
			[ -d "$BASH_USR_BIN" ] && unstat STATE_BASH_UBIN_DIR || :
		else
			: #ptrace "# Not implemented (STATE_BASH_UBIN_DIR)"
		fi
	}



	function lux_pre_install(){
		trace "try Resolve STATE_LUX_INST_DEF"
		if is_error STATE_LUX_INST_DEF; then

			repair_binvars "$BASH_USR_BIN"

			if [ -z "$QODEPARTY_INSTALL_DIR" ] || [ -z "$LUX_INSTALL_DIR" ]; then
				wtrace "Missing Dirs"
			fi

		else
			ptrace "#"
		fi

		trace "try Resolve STATE_LUX_INST_WRITE"
		if is_error STATE_LUX_INST_WRITE; then
			ftrace "#repair (STATE_LUX_INST_WRITE) not implemented"

			if [ -n "$LUX_INSTALL_DIR" ]; then
				mkdir -p "$LUX_INSTALL_DIR"

				if [ ! -d "$LUX_INSTALL_DIR" ]; then
					wtrace "Cant write to or create bin install dir"s
				fi
			fi

		else
			ptrace "#"
		fi
	}