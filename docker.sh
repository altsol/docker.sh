#!/bin/bash
function print_config_help {
	echo "CONFIG VARIABLES:"
	echo "==================================================";
	echo ""
	echo "RUNING VARIABLES"
	echo "--------------------------------------------------";
	echo "DOCKER_HOME        :"
	echo "IMAGE_NAME         :"
	echo "CONTAINER_NAME     :"
	echo "IMAGE_VERSION      :"
	echo "IMAGE_TAG          :"
	echo "DOCKER_FILE        :"
	echo "RUN_VOLUMES        :"
	echo "RUN_PORTS          :"
	echo "RUN_LINKS          :"
	echo "RUN_ENV            :"
	echo "RUN_HOSTS          :"
	echo "RUN_PARAMS         :"
	echo ""
	echo "TESTING VARIABLES  "
	echo "--------------------------------------------------";
	echo "DOCKER_TEST_DIR    :"
	echo "DOCKER_TEST_SCRIPT :"
	echo "DOCKER_TEST_SCRIPT_IN:"
	echo "DOCKER_TEST_SCRIPT_CLEAN:"
	echo ""
	echo "BUILDING VARIABLES  "
	echo "--------------------------------------------------";
	echo "DOCKER_BUILD_DIR   :"
	echo "DOCKER_BUILD_ARGS  :"

}
function print_help {
	1>&2 echo "Usage: $0 [OPTIONS] [COMMANDS]";
	1>&2 echo ""
	1>&2 echo "Options: "
	1>&2 echo "-------------------------------------------------";
	1>&2 echo " -d         : dry-run"
	1>&2 echo " -w DIR     : directory for files: conf, cidfile"
	1>&2 echo " -c conf    : load config"
	1>&2 echo " -p cidfile : load pid from file"
	1>&2 echo ""
	1>&2 echo "Commands:";
	1>&2 echo "-------------------------------------------------";
	1>&2 echo "help        :";
	1>&2 echo "help:config :";
	1>&2 echo "example     :";
	1>&2 echo "ps          :";
	1>&2 echo "build       :";
	1>&2 echo "tag         :";
	1>&2 echo "test        :";
	1>&2 echo "run         :";
	1>&2 echo "run:bash    : run container with bash entripoint";
	1>&2 echo "remove      :";
	1>&2 echo "start       :";
	1>&2 echo "stop        :";
	1>&2 echo 'bash        : $1: pwd';
	1>&2 echo "find        :";
	1>&2 echo "inspect     :";
	1>&2 echo "ip          :";
	1>&2 echo "info        :";
	1>&2 echo "top         :";
	1>&2 echo "logs        :";
	1>&2 echo "ls          :";
	1>&2 echo "cat         :";
	1>&2 echo "copy        :";
	1>&2 echo "exec        :";
	1>&2 echo "save        :";
	1>&2 echo "echo:vars   :";
	1>&2 echo "echo:conf   :";
	1>&2 echo "container   :";
	1>&2 echo "export:conf :";
	1>&2 echo "export:vars : create tmp file with config variable declarations, echo file name";
	1>&2 echo "make-default-conf:";
	1>&2 echo "edit        : edit file inside container";
	1>&2 echo "-------------------------------------------------";
	1>&2 echo ""
	1>&2 echo "example: $0 -d -c ex1.conf -c ex2.conf info remove build run"
	1>&2 echo ""

}

function config_example {
		echo "";
		echo "#docker.conf.sh:";
		echo "########################################";
		echo 'DOCKER_HOME="."';
		echo 'DOCKER_BUILD_DIR="."';
		echo 'IMAGE_NAME=my_repo';
		echo 'CONTAINER_NAME=my_container';
		echo 'DOCKER_FILE=Dockerfile';
		echo 'RUN_VOLUMES=("data/tmp:/tmp:rw" "data/var/log:/var/log:rw")'
		echo 'RUN_PORTS=("80:80" "19:19")'
		echo 'RUN_LINKS=("postgresql:postgres")'
		echo 'RUN_ENV=("MY_ENV_VARIABLE=my_value")'
		echo 'RUN_HOSTS=("test.local:127.0.0.1")'
		echo 'RUN_PARAMS="-d -it"';
		echo "";

}



CONF_VAR_NAMES=(
	"DOCKER_HOME"
	"DOCKER_BUILD_DIR"
	"DOCKER_BUILD_ARGS"
	"IMAGE_NAME"
	"CONTAINER_NAME"
	"IMAGE_VERSION"
	"IMAGE_TAG"
	"DOCKER_FILE"
	"RUN_VOLUMES"
	"RUN_PORTS"
	"RUN_LINKS"
	"RUN_ENV"
	"RUN_HOSTS"
	"RUN_PARAMS"
	"DOCKER_TEST_SCRIPT"
	"DOCKER_TEST_DIR"
	"DOCKER_TEST_SCRIPT_IN"
	"DOCKER_TEST_SCRIPT_CLEAN"
);


VARS="`set -o posix ; set`";
__MY_DIR=`readlink -f  .`;
__DEFAULT_DIR=1;
__DEFAULT_CONF=1;
__DEFAULT_CIDFILE=1;
__CONF="docker.conf.sh"
CIDFILE=".docker_container_id"
DRY_RUN=0
C=0;

while getopts "dc:p:w:"  opt; do
	case $opt in
		d)
			C=$((C+1))
			DRY_RUN=1
			#echo "#1 $((OPTIND-1))"
		;;
		w)
			if [[ "$OPTARG" == -* ]]; then
				1>&2 echo "EMPTY ARGUMENT -w";
				print_help;
				exit 13;
			fi
			__DEFAULT_DIR=0;
			__MY_DIR=`readlink -f  $OPTARG`;
			#DOCKER_HOME=$__MY_DIR;
			if [ ! -d $__MY_DIR ]; then
				1>&2 echo "-w DIRECTORY: $__MY_DIR NOT FOUND";
				exit 12;
			fi;
			C=$((C+2))
		;;
		p)
			if [[ "$OPTARG" == -* ]]; then
				1>&2 echo "EMPTY ARGUMENT -p";
				print_help;
				exit 13;
			fi
			CIDFILE=$OPTARG;
			__DEFAULT_CIDFILE=0;
			C=$((C+2))
		;;
		c)
			if [[ "$OPTARG" == -* ]]; then
				1>&2 echo "EMPTY ARGUMENT -c";
				print_help;
				exit 13;
			fi
			__DEFAULT_CONF=0;
			__CONF_TMP=`readlink -f $OPTARG`;
			if [ ! -f "${__CONF_TMP}" ]; then
				1>&2  echo "ERROR: ${__CONF_TMP} NOT FOUND";
				exit 10;
			fi;
			. $__CONF_TMP;
			C=$((C+2))
		;;
		\?)
			1>&2 echo "Invalid option: -$OPTARG"
		;;
	esac
done


if [ "$C" -gt "0" ]; then
	shift $C;
fi

if [[ "$__DEFAULT_CONF" == "1" ]]; then
		if [ -f "${__MY_DIR}/.docker.sh.conf" ]; then
				__CONF=.docker.sh.conf
		fi;
		if  [ -f ${__MY_DIR}/${__CONF} ]; then
			. ${__MY_DIR}/${__CONF}
			if [  -f ${__MY_DIR}/docker_user.conf.sh ]; then
					. ${__MY_DIR}/docker_user.conf.sh
			fi
			else
				if [[ "x$1" == "xexample" ]]; then
						config_example;
						exit 1;
				fi;
				if [[ "x$1" == "xhelp" ]]; then
						print_help;
						exit 1;
				fi;
				if [[ "x$1" == "xhelp:config" ]]; then
						print_config_help;
						exit 1;
				fi;
				1>&2  echo "ERROR: ${__MY_DIR}/${__CONF} NOT FOUND";
				1>&2  echo "try:";
				1>&2 echo "${0} example";
				1>&2 echo "${0} help";
				1>&2 echo "${0} help:config";
				1>&2 echo "";
				exit 10;
		fi
fi

#echo "2 RUN_ENV: ${RUN_ENV[*]}";
#echo "2 DRY RUN: $DRY_RUN";


if [[ "x${IMAGE_NAME}" == "x" ]]; then
	if [[ "x${IMAGE_REPOSITORY}" != "x" ]]; then
		IMAGE_NAME=$IMAGE_REPOSITORY
	else
		1>&2 echo "ERROR VARIABLE IMAGE_NAME NOT SET";
		exit 316;
	fi
fi;


#SCRIPT_CONF_VARS="`grep -vFe "$VARS" <<<"$(set -o posix ; set)"`"; unset VARS;
SCRIPT_CONF_VARS="`grep -vFe "$VARS" <<<"$(set -o posix ; set)" | grep -v ^VARS=|grep -v ^OPTIND=|grep -v ^C=|grep -v ^CIDFILE=|grep -v ^DRY_RUN=|grep -v ^__`"; unset VARS;

EXTRA_CONF_VAR_NAMES=();
	for v2 in ${SCRIPT_CONF_VARS}; do
		#echo ": $v2";
		#if [[ ! $v2  == \[* ]] && [[ ! $v2  == \(\[* ]]; then
		if [[ ! $v2  == \[* ]]; then
			tmp0=(${v2//=/ })
			tmp1=${tmp0[0]}
			flag1=0;
			for v1 in ${CONF_VAR_NAMES[@]}; do
				if [[ $tmp1 == $v1 ]]; then
					flag1=1;
				fi
			done;
			if [[ "$flag1" == "0" ]];then
					EXTRA_CONF_VAR_NAMES+=($tmp1)
			fi

		fi;
	done;

ALL_CONF_VAR_NAMES=("${CONF_VAR_NAMES[@]}" "${EXTRA_CONF_VAR_NAMES[@]}")

if [[ "x${CONTAINER}" == "x" ]]; then
	if [  -f ${CIDFILE} ]; then
		CONTAINER=$(cat "${CIDFILE}")
	fi;
fi;

if [ -z "$1" ]; then
	#echo "usage: $0 help"
	print_help
		exit
fi

	if [ -z "$DOCKER_HOME" ]; then
		1>&2 echo "ERROR: VARIABLE DOCKER_HOME NOT SET";
		exit 16;
	fi;

	if [[ "${__DEFAULT_DIR}" == "0" ]];then
		DOCKER_HOME_FULL=$__MY_DIR;
	else
		DOCKER_HOME_FULL=`readlink -f  $DOCKER_HOME`;
	fi

	if [[ ! -d ${DOCKER_HOME_FULL} ]]; then
		1>&2 echo "DOCKER HOME DIR: ${DOCKER_HOME_FULL} NOT FOUND";
		exit 22;
	fi;


	if [ ! -z "$DOCKER_BUILD_DIR" ]; then
		if [[ "$DOCKER_BUILD_DIR" != /* ]]; then
			DOCKER_BUILD_DIR="${DOCKER_HOME_FULL}/${DOCKER_BUILD_DIR}";
		fi
		DOCKER_BUILD_DIR_FULL=`readlink -f  $DOCKER_BUILD_DIR`;
	fi

	if [ ! -z "$DOCKER_TEST_DIR" ]; then
		if [[ "$DOCKER_TEST_DIR" != /* ]]; then
			DOCKER_TEST_DIR="${DOCKER_HOME_FULL}/${DOCKER_TEST_DIR}";
		fi
		DOCKER_TEST_DIR_FULL=`readlink -f  $DOCKER_TEST_DIR`;
	fi


	if [ ! -z "$CIDFILE" ]; then
		if [[ "$CIDFILE" != /* ]]; then
			CIDFILE="${DOCKER_HOME_FULL}/${CIDFILE}";
		fi
		CIDFILE=`readlink -f  $CIDFILE`;
	fi





function check_docker_build_dir {
	if [[ "x${DOCKER_BUILD_DIR}" == "x" ]]; then
		1>&2 echo "ERROR: VARIABLE DOCKER_BUILD_DIR NOT SET";
		exit 16;
	fi;
	if [[ ! -d ${DOCKER_BUILD_DIR_FULL} ]]; then
		1>&2 echo "DOCKER BUILD DIR: ${DOCKER_BUILD_DIR_FULL} NOT FOUND";
		exit 16;
	fi;
}



RUN_OK="1";
#if [[ -z "$RUN_PARAMS" && -z "$RUN_ENV" && -z "$RUN_LINKS" && -z "$RUN_PORTS"  && -z "$RUN_VOLUMES" ]]; then
#	RUN_OK="0";
#fi
if [[ ! -z "$ALLOW_RUN"  && "$ALLOW_RUN" -eq "0" ]]; then
	RUN_OK="0";
fi;



if [ -z "${IMAGE_VERSION}" ]; then
	DOCKER_NAME="${IMAGE_NAME}"
else
	DOCKER_NAME="${IMAGE_NAME}:${IMAGE_VERSION}"
fi

if [ ! -z "${IMAGE_TAG}" ]; then
	TAG_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
fi


function check_status {

	if [ "$?" -ne "0" ]; then
			1>&2  echo "ERROR! ";
		exit 3;
	fi;
}

###########################################################
###########################################################
###########################################################


function _test {


	if [[ "x${DOCKER_TEST_DIR}" == "x" &&  "x${DOCKER_BUILD_DIR}" != "x" ]]; then
			DOCKER_TEST_DIR = $DOCKER_BUILD_DIR;
	fi

	if [[ "x${DOCKER_TEST_DIR}" == "x" ]]; then
		1>&2 echo "ERROR: VARIABLE DOCKER_TEST_DIR NOT SET";
		exit 16;
	fi;
	if [[ ! -d ${DOCKER_TEST_DIR_FULL} ]]; then
		1>&2 echo "DOCKER TEST DIR: ${DOCKER_TEST_DIR_FULL} NOT FOUND";
		exit 22;
	fi;


	if [[  "x${DOCKER_TEST_SCRIPT}" == "x" ]]; then
		1>&2 echo " DOCKER_TEST_SCRIPT not set";
	fi



	function ASSERT {
		if [[ "$2" = "$3" ]]; then
			echo -e "\e[32m TEST OK: $1 \e[39m";
		else
			echo -e "\e[31m TEST FAILURE: $1\e[39m"
		fi
	};
	function ASSERT_ERROR {
		echo -e "\e[31m TEST FAILURE: $1\e[39m"
	}
	function ASSERT_OK {
		echo -e "\e[32m TEST OK: $1 \e[39m";
	}

	CDIR=`pwd`;
	if [[ "x${DOCKER_TEST_SCRIPT_CLEAN}" != "x" ]]; then
		cd $DOCKER_TEST_DIR_FULL;
		echo -e "\e[96m --> TEST_PATH : `pwd`\e[39m";
		echo -e "\e[96m --> TEST SCRIPT CLEAN: ${DOCKER_TEST_SCRIPT_CLEAN}\e[39m"
		. ./${DOCKER_TEST_SCRIPT_CLEAN}
		cd ${CDIR};
	fi

	echo -e "\e[96m --> Starting container $DOCKER_NAME";
	CIDFILE=/tmp/docker.sh.test.pid
	echo -e "\e[33m";
	remove >/dev/null 2>&1;
	_run;
	echo -e "\e[39m";
	sleep 1;
	echo_conf > /tmp/docker.sh.test.conf
	#echo "TEST CONFIG"
	#echo "--------------------------------------------------"
	#cat /tmp/docker.sh.test.conf
	#echo "--------------------------------------------------"

	DOCKER_SH="docker.sh -c /tmp/docker.sh.test.conf -p /tmp/docker.sh.test.pid"
	cd $DOCKER_TEST_DIR_FULL;
	echo -e "\e[96m --> TEST_PATH : `pwd`\e[39m";

	if [[ ! -s  ./${DOCKER_TEST_SCRIPT} ]]; then
		1>&2 echo "ERROR: CANOT FIND $PWD/${DOCKER_TEST_SCRIPT}";
		exit 24;
	fi
	#echo "TEST:  ${DOCKER_TEST_DIR_FULL}/${DOCKER_TEST_SCRIPT}"
	echo -e "\e[96m --> TEST SCRIPT: ${DOCKER_TEST_SCRIPT}\e[39m"

	. ./${DOCKER_TEST_SCRIPT}

	if [[ -s  ./${DOCKER_TEST_SCRIPT_IN} ]]; then
		TEST_LIB=/tmp/docker_sh_test_lib
		echo ""> $TEST_LIB
		declare -f ASSERT >>$TEST_LIB
		echo "">> $TEST_LIB
		declare -f ASSERT_ERROR >>$TEST_LIB
		echo "">> $TEST_LIB
		declare -f ASSERT_OK >>$TEST_LIB
		echo "">> $TEST_LIB

		docker cp $TEST_LIB ${CONTAINER_NAME}:/tmp
		TEST_SCRIPT_IN=/tmp/docker_test_script_in
		echo "#!/bin/bash" > ${TEST_SCRIPT_IN}
		echo ". $TEST_LIB" >> ${TEST_SCRIPT_IN}
		echo "">>${TEST_SCRIPT_IN}
		cat ${DOCKER_TEST_SCRIPT_IN} |egrep -v "#!/bin/bash" >> ${TEST_SCRIPT_IN}
		chmod +x  ${TEST_SCRIPT_IN}
		docker cp ${TEST_SCRIPT_IN} ${CONTAINER_NAME}:/tmp

		echo -e "\e[96m --> exec internal test\e[39m";
		${DOCKER_SH} exec ${TEST_SCRIPT_IN}
	fi

	echo -e "\e[96m --> Stopping container"
	${DOCKER_SH} remove >/dev/null
	echo -e "\e[39m";

}


function build {
	check_docker_build_dir;

	BUILD_PATH=$DOCKER_BUILD_DIR_FULL;

	MY_BUILD_PARAMS="";
	for i in ${DOCKER_BUILD_ARGS[@]}; do
		MY_BUILD_PARAMS="$MY_BUILD_PARAMS ${i}";
	done;

	if [ "$DRY_RUN" -eq "0" ]; then
		cd $BUILD_PATH;
		pwd
		echo $DOCKER_CMD;
		echo "docker build $MY_BUILD_PARAMS -f ${DOCKER_HOME_FULL}/${DOCKER_FILE} -t $DOCKER_NAME   --rm .";
		docker build $MY_BUILD_PARAMS -f ${DOCKER_HOME_FULL}/${DOCKER_FILE} -t $DOCKER_NAME   --rm .
	else
		DOCKER_CMD="docker build $MY_BUILD_PARAMS -f ${DOCKER_HOME_FULL}/${DOCKER_FILE} -t $DOCKER_NAME --rm .";
		echo "";
		echo "cd $BUILD_PATH"
		echo $DOCKER_CMD;
	fi

	check_status;
}


function tag {

	check_docker_build_dir;

	if [ -z "${TAG_NAME}" ]; then
			1>&2 echo "ERROR: VARIABLE TAG_NAME NOT SET";
			exit 16;
	fi;

	BUILD_PATH=$DOCKER_BUILD_DIR_FULL;

	if [ "$DRY_RUN" -eq "0" ]; then
		cd $BUILD_PATH;
		pwd
		echo $DOCKER_CMD;
		docker tag -f ${DOCKER_NAME} ${TAG_NAME}
	else
		DOCKER_CMD="docker tag -f docker tag -f ${DOCKER_NAME} ${TAG_NAME}";
		echo "";
		echo "cd $BUILD_PATH"
		echo $DOCKER_CMD;
	fi

	check_status;
}



function _run {

	ENTRYPOINT="";
	if [[ -n "$1" ]]; then
		ENTRYPOINT="$1"
	fi

	if [[ "$RUN_OK" -eq "0" ]]; then
		1>&2  echo "run not supported";
		exit 5;
	fi

	MY_VOLUMES="";
	for v in ${RUN_VOLUMES[@]}; do

		VOL_OK="-v";
		VOL=$(echo $v | tr ":" "\n")
		i=0;
		for m in $VOL
		do
			i=$((i + 1))
			if [ "$i" -eq 1 ]; then
				if [[ $m != /* ]]; then
					ok="${DOCKER_HOME_FULL}/$m";
				else
					ok=$m;
				fi
				VOL_OK="$VOL_OK ${ok}";
			else
				VOL_OK="$VOL_OK:${m}";
			fi;
		done

		MY_VOLUMES="$MY_VOLUMES $VOL_OK";
	done;

	#echo "VOLUMES: $MY_VOLUMES";

	MY_PORTS="";
	for p in ${RUN_PORTS[@]}; do
		MY_PORTS="$MY_PORTS -p $p";
	done;


	MY_LINKS="";
	for p in ${RUN_LINKS[@]}; do
		MY_LINKS="$MY_LINKS --link $p";
	done;


	MY_PARAMS="";
	for i in ${RUN_PARAMS[@]}; do
		MY_PARAMS="$MY_PARAMS ${i}";
	done

	ENV_FILE=`mktemp`
	AI=${!RUN_ENV[*]}
	for i in $AI; do
		echo ${RUN_ENV[i]} >> $ENV_FILE
	done

	MY_HOSTS="";
	for i in ${RUN_HOSTS[@]}; do
		MY_HOSTS="$MY_HOSTS --add-host=${i}";
	done

	if [[ -n "$ENTRYPOINT" ]]; then
		#DOCKER_CMD="docker run -i -t $IMAGE_NAME ${ENTRYPOINT}";
		DOCKER_CMD="docker run  -i --entrypoint  ${ENTRYPOINT} -t $IMAGE_NAME ";
	else
		if [[ -s $ENV_FILE ]]; then
			ENV_CMD="--env-file $ENV_FILE"
		else
			ENV_CMD=""
		fi;
		DOCKER_CMD="docker run --cidfile="$CIDFILE" $ENV_CMD $MY_PARAMS $MY_VOLUMES $MY_PORTS $MY_LINKS $MY_HOSTS --name $CONTAINER_NAME $DOCKER_NAME";
		#DOCKER_CMD="docker run  $ENV_CMD $MY_PARAMS $MY_VOLUMES $MY_PORTS $MY_LINKS $MY_HOSTS --name $CONTAINER_NAME $DOCKER_NAME";
	fi
	if [ "$DRY_RUN" -eq "0" ]; then
		if [[ -s $ENV_FILE ]]; then
			echo "ENV_FILE:"
			cat $ENV_FILE
			echo ""
		fi
		echo "-------------------------------------------------"
		echo $DOCKER_CMD;
		echo "-------------------------------------------------"

		#ID=$($DOCKER_CMD)
		ID=`$DOCKER_CMD`

		check_status;

		docker inspect $ID  >/dev/null 2>&1 || rm "$CIDFILE"

		#echo $ID
		#echo $ID>$CIDFILE
	else
		if [[ -s $ENV_FILE ]]; then
			echo "ENV_FILE:"
			cat $ENV_FILE
			echo "";
		fi;
		echo $DOCKER_CMD;
	fi

	#echo "rm ENV: $ENV_FILE"
	rm  $ENV_FILE



}



function exec_bash  {
	if [ "$DRY_RUN" -eq "0" ]; then
		if [ -z "$1" ]; then
			docker exec -i -t $CONTAINER /bin/bash -l
		else
			docker exec -i -t $CONTAINER  /bin/sh -c "cd $1; bash -l"
		fi
	else
		if [ -z "$1" ]; then
			echo "docker exec -i -t $CONTAINER /bin/bash -l"
		else
			echo "docker exec -i -t $CONTAINER /bin/sh -c 'cd $1; bash -l'"
		fi
	fi
	exit;

}

function remove {

if [ "$DRY_RUN" -eq "0" ]; then
	echo "docker stop $CONTAINER_NAME";
	echo "docker rm -v $CONTAINER_NAME";
	if [[ -f $CIDFILE ]];then
		echo "rm $CIDFILE";
	fi
	docker stop $CONTAINER_NAME 2>/dev/null
	docker rm -v $CONTAINER_NAME 2>/dev/null
	if [[ -f $CIDFILE ]];then
		rm $CIDFILE
	fi
else
	echo "docker stop $CONTAINER_NAME";
	echo "docker rm -v $CONTAINER_NAME";
	if [[ -f $CIDFILE ]];then
		echo "rm $CIDFILE";
	fi
fi

}


function exec {
	if [ -z "$1" ]; then
		1>&2  echo "Usage: $0 exec command [arguments]";
			exit
	fi

	if [ "$DRY_RUN" -eq "0" ]; then
		#echo "docker exec -i -t $CONTAINER $@"
		#echo "";
		docker exec -i -t $CONTAINER $@
	else
		echo "docker exec -i -t $CONTAINER $@"
	fi
	exit;
}

function _copy {
	if [ -z "$1" ]; then
		1>&2  echo "Usage: $0 copy [PATH_IN] [PATH_OUT]";
			exit
	fi
	if [ -z "$2" ]; then
		1>&2  echo "Usage: $0 copy [PATH_IN] [PATH_OUT]";
			exit
	fi

	#if [ -z "${CONTAINER}" ]; then
	#		echo "canot find container";
	#	exit;
	#fi

	echo "docker cp $CONTAINER_NAME:$1 $2";
	docker cp $CONTAINER_NAME:$1 $2
	exit;

}

function edit {
	if [ -z "$1" ]; then
		1>&2  echo "Usage: $0 edit [FILE]";
			exit
	fi

	if [ -z "${CONTAINER}" ]; then
		1>&2  echo "canot find container";
		exit;
	fi

	FILEPATH="/var/lib/docker/aufs/mnt/${CONTAINER}/$1";

	echo $FILEPATH
	sudo gedit $FILEPATH
	exit

}

function _ls {
	if [ -z "$1" ]; then
		1>&2  echo "Usage: $0 ls [PATH]";
			exit;
	fi

	#FILEPATH="/var/lib/docker/aufs/mnt/${CONTAINER}/$2";
	#docker exec -i -t $CONTAINER_NAME file $2
	docker exec -i -t $CONTAINER_NAME ls -altr $1
	exit;

}

function _cat {
	if [ -z "$1" ]; then
			1>&2  echo "Usage: $0 cat [PATH]";
			exit 1;
	fi

	docker exec -i -t $CONTAINER_NAME cat $1
	exit;

}

function _top {
	docker top $CONTAINER_NAME
	check_status;
}

function logs {
	docker logs $CONTAINER_NAME
	check_status;
}

function _find {
	docker exec -i -t $CONTAINER_NAME find /
	check_status;
}


function inspect {

	if [ -z "${CONTAINER}" ]; then
		docker inspect $CONTAINER_NAME
	else
		echo "container:  ${CONTAINER}";
		docker inspect $CONTAINER
	fi

	check_status;
}

function get_ip {
	if [ -z "${CONTAINER}" ]; then
		1>&2  echo "canot find container";
		exit;
	fi
	#echo "container:  ${CONTAINER}";
	docker inspect $CONTAINER | grep \"IPAddress\": | sed -e 's/.*: "//; s/".*//'|tail -1
	exit;
}

function _start {
	docker start $CONTAINER_NAME
	check_status;
}

function _save {
	echo "docker save $DOCKER_NAME > $CONTAINER_NAME.tar"
	docker save $DOCKER_NAME > $CONTAINER_NAME.tar
	check_status;
}

function _stop {
	docker stop $CONTAINER_NAME
}

function print_ps {
	docker ps
}
function print_info {
	echo   "# ------------------------------------------------------------------------------------------------";
	if [[ ! "x$CONTAINER" = "x" ]]; then
		echo   "CONTAINER             : $CONTAINER";
		echo   "CONTAINER_ROOT        : /var/lib/docker/aufs/mnt/${CONTAINER}";
	fi
	echo   "DOCKER_NAME           : $DOCKER_NAME";
	echo   "DOCKER_HOME_FULL      : $DOCKER_HOME_FULL";
	echo   "DOCKER_BUILD_DIR_FULL : $DOCKER_BUILD_DIR_FULL";
	echo   "DOCKER_TEST_DIR_FULL  : $DOCKER_TEST_DIR_FULL"
	echo   "DOCKER_TEST_SCRIPT    : $DOCKER_TEST_SCRIPT"
	echo   "EXTRA_CONF_VAR_NAMES  : ${EXTRA_CONF_VAR_NAMES[*]}";
	echo   "DOCKER_FILE           : $DOCKER_FILE";
	echo   "IMAGE_NAME            : $IMAGE_NAME";
	echo   "CONTAINER_NAME        : $CONTAINER_NAME";
	echo   "PIDFILE               : $CIDFILE"
	echo "# RUN PARAMETERS:"
	printf 'RUN_HOSTS       : %s\n' "${RUN_HOSTS[*]}";
	printf 'RUN_ENV         : %s\n' "${RUN_ENV[*]}";
	printf 'RUN_PORTS       : %s\n' "${RUN_PORTS[*]}";
	printf 'RUN_VOLUMES     : %s\n' "${RUN_VOLUMES[*]}";
	printf 'RUN_LINKS       : %s\n' "${RUN_LINKS[*]}";
	printf 'RUN_PARAMS      : %s\n' "${RUN_PARAMS[*]}";


	#for SV in ${CONF_VAR_NAMES[*]};do
		#	echo "${SV} : ${!SV}"
		#	#declare -p $SV 2>/dev/null;
	#done;
	echo ""
	echo "# EXTRA_CONF_VARIABLES:";
	for SV in ${EXTRA_CONF_VAR_NAMES[*]};do
		echo "${SV} : ${!SV}"
		#declare -p $SV 2>/dev/null;
	done;
	echo   "# ------------------------------------------------------------------------------------------------";




}


function _echo_var {
	if [[ ! "x${!1}" == "x" ]];then
		if [[ "$VN" == "DOCKER_HOME" ]]; then
			declare -p  'DOCKER_HOME_FULL'| sed s/DOCKER_HOME_FULL=/DOCKER_HOME=/;
		elif [[ "$VN" == "DOCKER_BUILD_DIR" ]]; then
			declare -p  'DOCKER_BUILD_DIR_FULL'| sed s/DOCKER_BUILD_DIR_FULL=/DOCKER_BUILD_DIR=/;
		elif [[ "$VN" == "DOCKER_TEST_DIR" ]]; then
			declare -p  'DOCKER_TEST_DIR_FULL'| sed s/DOCKER_TEST_DIR_FULL=/DOCKER_TEST_DIR=/;
		else
			declare -p $1
		fi
	fi
}



function echo_vars {
	for VN in ${ALL_CONF_VAR_NAMES[@]};do
		_echo_var $VN;
	done;
}

function export_vars {
	VAR_FILE=`mktemp`;
	echo_vars > $VAR_FILE
	echo $VAR_FILE
}

function echo_conf {
	echo "####################################################################"
	echo "#generated:  `date +%Y-%m-%d_%H:%M:%S" "%Z -u`"
	echo "####################################################################"
	echo ""
	echo "#MAIN PARAMS:"

	#DOCKER_HOME="."
	#DOCKER_BUILD_DIR="."

	for VN in ${CONF_VAR_NAMES[@]};do
		_echo_var $VN;
	done;
	echo "#EXTRA PARAMS:"
	for VN in ${EXTRA_CONF_VAR_NAMES[@]};do
		_echo_var $VN;
	done;

}


function make_default_conf {

	CONF_FILE=.docker.sh.conf
	echo_conf > $CONF_FILE
	echo "$CONF_FILE  CREATED:";
	cat $CONF_FILE

}


FIRST_ARG=1
function print_banner  {
	if [ "$FIRST_ARG" -eq "0" ]; then
		arg=$1;
		echo "-------------------------------------------------------------------------------------";
		echo "${arg}:";
		echo "-------------------------------------------------------------------------------------";
		echo ""
	fi
}

while (( "$#" )); do
	var=$1;
	shift

	case $var in
				"help")
					print_banner $var;
					print_help;
					;;
					"help:config")
					print_banner $var;
				print_config_help;
					;;
					 "build")
					print_banner $var;
				build;
					;;
				"tag")
					print_banner $var;
				tag;
					;;
				"test")
					print_banner $var;
				_test;
					;;
					"run")
						print_banner $var;
						_run;
					;;
			"run:bash")
				print_banner $var;
				run "/bin/bash";
					;;
				"bash")
					print_banner $var;
				exec_bash $@;
					;;
				"remove")
					print_banner $var;
				remove;
					;;
				"exec")
					exec $@;
					;;
				"copy")
					print_banner $var;
				_copy $@;
					;;
				"edit")
					print_banner $var;
				edit $@;
					;;
				"ls")
					print_banner $var;
				_ls $@;
					;;
				"cat")
				_cat $@;
					;;
			"find")
				print_banner $var;
				_find;
			;;
			"top")
				print_banner $var;
				_top;
			;;
			"logs")
				print_banner $var;
				logs;
			;;
			"inspect")
				print_banner $var;
				inspect;
			;;
			"ip")
				get_ip;
			;;
			"container")
				echo $CONTAINER;
				exit;
			;;
			"start")
				print_banner $var;
				_start;
			;;
			"stop")
				print_banner $var;
				_stop;
			;;
			"info")
				print_banner $var;
				print_info;
			;;
			"ps")
				print_banner $var;
				print_ps;
			;;
			"save")
				print_banner $var;
				_save;
			;;
			"example")
				print_banner $var;
				config_example;
			;;
			"echo:conf")
				print_banner $var;
				echo_conf;
			;;
			"make-default-conf")
				print_banner $var;
				make_default_conf;
			;;
			"echo:vars")
				print_banner $var;
				echo_vars;
			;;
			"export:vars")
				export_vars;
			;;
		 *)
							 1>&2  echo "UNKNOWN COMMAND: $var";
					;;
	 esac
	echo "";
	FIRST_ARG=0
done






