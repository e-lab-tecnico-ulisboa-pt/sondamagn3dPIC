#!/bin/bash
#
# description: Starts and stops the mag3d daemon \
#


BASE_USER=elab
BASE_USER_HOMEDIR=~elab
EXPERIMENT_NAME=mag3d
DEPLOY_DIR="/home/elab/rec-deployment/mag3d"
CURDIR=`pwd`
CURUSER=`id -nu`
ADDITIONAL_SERVICE_START=""
ADDITIONAL_SERVICE_STOP=""

java_is_running() {
	[[ -f "$DEPLOY_DIR/mag3d.pid" ]] || return 1
	PID=`cat $DEPLOY_DIR/mag3d.pid`
	ps aux | grep $PID | grep java > /dev/null 2>&1
	VAR1=$?
	kill -0 $PID > /dev/null 2>&1
	VAR2=$?
	[ $VAR1 -eq 0 ] && [ $VAR2 -eq 0 ] && return 0 || return 1
}


start() {
	if ( java_is_running ); then
		echo "The service mag3d is already running"
		return 1
	fi

	if [ "x$ADDITIONAL_SERVICE_START" != "x" ]; then
		echo "Starting additional service '$ADDITIONAL_SERVICE_START'..."
		if [ "x$CURUSER" != "x$BASE_USER" ]; then
			su -m -l $BASE_USER -c "cd $DEPLOY_DIR; nohup $ADDITIONAL_SERVICE_START 2>&1 >/dev/null 2>/dev/null"
		else
			cd $DEPLOY_DIR
			nohup $ADDITIONAL_SERVICE_START 2>&1 >/dev/null 2>/dev/null
		fi
		if [ $? -eq 0 ]; then
			echo "OK"
		else
			echo "Not OK"
			return 1
		fi
	fi
	
	echo "Starting mag3d service..."

	if [ "x$CURUSER" != "x$BASE_USER" ]; then
		su -m -l $BASE_USER -c "cd $DEPLOY_DIR; nohup $DEPLOY_DIR/Startmag3dDriver.sh 2>&1 >/dev/null 2>/dev/null"
	else
		cd $DEPLOY_DIR
		nohup $DEPLOY_DIR/Startmag3dDriver.sh 2>&1 >/dev/null 2>/dev/null
	fi

	if [ $? -eq 0 ]; then
		echo "OK"
		if [ "x$CURUSER" != "x$BASE_USER" ]; then
			su -m -l $BASE_USER -c "touch $DEPLOY_DIR/mag3d.lock"
		else
			touch $DEPLOY_DIR/mag3d.lock
		fi
		return 0
	else
		echo "Not OK"
		return 1
	fi
}


stop() {
	if ( java_is_running ); then

		if [ "x$ADDITIONAL_SERVICE_STOP" != "x" ]; then
			echo "Stoping additional service '$ADDITIONAL_SERVICE_STOP'..."
			if [ "x$CURUSER" != "x$BASE_USER" ]; then
				su -m -l $BASE_USER -c "cd $DEPLOY_DIR; nohup $ADDITIONAL_SERVICE_STOP 2>&1 >/dev/null 2>/dev/null"
			else
				cd $DEPLOY_DIR
				nohup $ADDITIONAL_SERVICE_STOP 2>&1 >/dev/null 2>/dev/null
			fi
			if [ $? -eq 0 ]; then
				echo "OK"
			else
				echo "Not OK"
				return 1
			fi
		fi


		PID=`cat $DEPLOY_DIR/mag3d.pid`

		echo "Stopping mag3d service..."
		if [ "x$CURUSER" != "x$BASE_USER" ]; then
			su -m -l $BASE_USER -c "kill $PID"
		else
			kill $PID
		fi

		if [ $? -eq 0 ]; then
			[ -f $DEPLOY_DIR/mag3d.lock ] && rm -rf $DEPLOY_DIR/mag3d.lock
			[ -f $DEPLOY_DIR/mag3d.pid ] && rm -rf $DEPLOY_DIR/mag3d.pid
			echo "OK"
			return 0
		else
			echo "Not OK"
			return 1
		fi
	else
		echo "The service mag3d is not running"
		return 1
	fi
}


restart() {
	stop
	start
}


status() {
	if ( java_is_running ); then
		echo "The service mag3d is running"
	else
		echo "The service mag3d is not running"
	fi
}


case "$1" in
	start)
		start
	;;
	stop)
		stop
	;;
	restart)
		restart
	;;
	status)
		status
	;;
	*)
		echo "Usage: $0 {start|stop|restart|status}"
		exit 1
esac

exit $?
