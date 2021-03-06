#!/bin/bash
#
# Copyright (c) Members of the EGEE Collaboration. 2004-2010.
# See http://www.eu-egee.org/partners for details on the copyright holders.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# show help and usage
progname=`basename $0`
showHelp()
{
cat << EndHelpHeader
Script for testing permission settings on L&B files

Prerequisities:
   - L&B installed, configured and running

     GLITE_USER
     GLITE_LOCATION
     GLITE_LB_LOCATION_ETC

Tests called:

    checking file permissions

Returned values:
    Exit TEST_OK: Test Passed
    Exit TEST_ERROR: Test Failed
    Exit 2: Wrong Input

EndHelpHeader

	echo "Usage: $progname [OPTIONS]"
	echo "Options:"
	echo " -h | --help            Show this help message."
	echo " -o | --output 'file'   Redirect all output to the 'file' (stdout by default)."
	echo " -t | --text            Format output as plain ASCII text."
	echo " -c | --color           Format output as text with ANSI colours (autodetected by default)."
	echo " -x | --html            Format output as html."
}

test_perms()
{
FAIL=0
for line in `$SYS_CAT $4`;do
	if [ -e $line ]; then
		$SYS_STAT -c=%A%U%G $line | $SYS_GREP -E "^=$1$2$3" > /dev/null
		if [ $? -gt 0 ]; then
			print_error "Incorrect permissions for $line"
			$SYS_LS -l $line
			FAIL=2
		fi
	else
		printf "File $line does not exist. "
		if [ $FAIL = 0 ]; then
			FAIL=1
		fi
	fi
done

if [ $FAIL = 2 ]; then
	test_failed
else
	if [ $FAIL = 1 ]; then
		test_skipped
	else
		test_done
	fi
fi
}

# read common definitions and functions
COMMON=lb-common.sh
if [ ! -r ${COMMON} ]; then
	printf "Common definitions '${COMMON}' missing!"
	exit 2
fi
source ${COMMON}

logfile=$$.tmp
flag=0
while test -n "$1"
do
	case "$1" in
		"-h" | "--help") showHelp && exit 2 ;;
		"-o" | "--output") shift ; logfile=$1 flag=1 ;;
		"-t" | "--text")  setOutputASCII ;;
		"-c" | "--color") setOutputColor ;;
		"-x" | "--html")  setOutputHTML ;;
	esac
	shift
done

DEBUG=2

##
#  Starting the test
#####################

{
test_start


# check_binaries
printf "Testing if all binaries are available"
check_binaries $GRIDPROXYINFO $SYS_GREP $SYS_CAT $SYS_STAT $SYS_LS
if [ $? -gt 0 ]; then
	test_failed
else
	test_done
fi

if [ "$GLITE_USER" = "" ]; then
	GLITE_USER="glite"
fi
if [ "$GLITE_LOCATION" = "" ]; then
	GLITE_LOCATION="/opt/glite"
fi
if [ "$GLITE_LB_LOCATION_ETC" = "" ]; then
	GLITE_LB_LOCATION_ETC="/opt/glite/etc"
fi
GLITE_HOME=`getent passwd ${GLITE_USER} | cut -d: -f6`


#lrwxrwxrwx 1 root root 29 Aug  2 10:31 /etc/glite-lb-dbsetup.sql -> glite-lb/glite-lb-dbsetup.sql
#lrwxrwxrwx 1 root root 37 Aug  2 10:31 /etc/glite-lb-index.conf.template -> glite-lb/glite-lb-index.conf.template
#-r--r--r-- 1 root root 990 May 10 07:50 /etc/glite-lb/harvester-test-dbsetup.sql

$SYS_CAT << EOF > 400glite
$GLITE_HOME/.certs/hostkey.pem
EOF

$SYS_CAT << EOF > 644glite
/var/log/glite/glite-lb-lcas.log
/var/log/glite/glite-lb-pproxy-purge.log
/var/log/glite/glite-lb-server-purge.log
$GLITE_HOME/.bashrc
$GLITE_HOME/.certs/hostcert.pem
$GLITE_HOME/.bash_profile
$GLITE_HOME/.bash_logout
EOF

$SYS_CAT << EOF > 644root
$GLITE_LB_LOCATION_ETC/glite-lb/msg.conf
$GLITE_LB_LOCATION_ETC/glite-lb/log4crc
$GLITE_LB_LOCATION_ETC/glite-lb/glite-lb-index.conf.template
$GLITE_LB_LOCATION_ETC/glite-lb/glite-lb-harvester.conf
$GLITE_LB_LOCATION_ETC/glite-lb/msg.conf.example
$GLITE_LB_LOCATION_ETC/glite-lb/glite-lb-dbsetup.sql
$GLITE_LB_LOCATION_ETC/glite-lb/lcas.db
$GLITE_LB_LOCATION_ETC/glite-lb/glite-lb-authz.conf
$GLITE_LB_LOCATION_ETC/glite-lb/site-notif.conf
$GLITE_LB_LOCATION_ETC/gLiteservices
$GLITE_LB_LOCATION_ETC/logrotate.d/glite-lb-lcas
$GLITE_LB_LOCATION_ETC/logrotate.d/glite-lb-purge
$GLITE_LB_LOCATION_ETC/mysql/conf.d/glite-lb-server.cnf
$GLITE_LOCATION/share/wsdl/glite-lb/glue2.xsd
$GLITE_LOCATION/share/wsdl/glite-lb/LB.wsdl
$GLITE_LOCATION/share/wsdl/glite-lb/LBTypes.wsdl
$GLITE_LOCATION/interface/glite-lb/lb-job-attrs2.xsd
$GLITE_LOCATION/interface/glite-lb/lb-job-record.xsd
$GLITE_LOCATION/interface/glite-lb/lb-job-attrs.xsd
EOF

$SYS_CAT << EOF > 644or664glite
$GLITE_LB_LOCATION_VAR/glite-lb-bkserverd.pid
$GLITE_LB_LOCATION_VAR/glite-lb-interlogd.pid
$GLITE_LB_LOCATION_VAR/glite-lb-logd.pid
$GLITE_LB_LOCATION_VAR/glite-lb-notif-interlogd.pid
$GLITE_LB_LOCATION_VAR/glite-lb-proxy-interlogd.pid
EOF

$SYS_CAT << EOF > 755root
$GLITE_LB_LOCATION_ETC/glite-lb/glite-lb-migrate_db2version20
$GLITE_LOCATION/share/glite-lb/msg-brokers
EOF

$SYS_CAT << EOF > s700glite
/tmp/lb_proxy_serve.sock
/tmp/lb_proxy_store.sock
/tmp/glite-lb-notif.sock
/tmp/glite-lbproxy-ilog.sock
/tmp/interlogger.sock
EOF

printf "Checking permissions and ownership for\n  Host key... "
test_perms "-r..------" $GLITE_USER $GLITE_USER 400glite

printf "  $GLITE_USER's home dir files... "
test_perms ".rw.r-.r-." $GLITE_USER $GLITE_USER 644glite

printf "  Config files..."
test_perms ".rw.r-.r-." root root 644root

printf "  PIDs..."
test_perms "-rw-r.-r--" $GLITE_USER $GLITE_USER 644or664glite

printf "  Admin scripts..."
test_perms "-rwxr-xr-x" root root 755root

printf "  Sockets... "
test_perms "srw.------" $GLITE_USER $GLITE_USER s700glite


$SYS_RM 400glite 644glite 644root 664glite 755root s700glite

test_end
} 

exit $TEST_OK

