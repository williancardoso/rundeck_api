#!/bin/bash

#usage: runjob.sh <server URL | - > <job ID>

errorMsg() {
   echo "$*" 1>&2
}

DIR=$(cd `dirname $0` && pwd)

# accept url argument on commandline, if '-' use default
url=$1
if [ "-" == "$url" ] ; then
    url='http://localhost:4440'
fi
loginurl="${url}/j_security_check"

# curl opts to use a cookie jar, and follow redirects, showing only errors
CURLOPTS="-s -S -L -c $DIR/cookies -b $DIR/cookies"

#curl command to use with opts
CURL="curl $CURLOPTS"

# submit login request
echo "Login..."
$CURL -d j_username=admin -d j_password=admin $loginurl > $DIR/curl.out 
if [ 0 != $? ] ; then
    errorMsg "failed login request to ${loginurl}"
    exit 2
fi

# make sure result doesn't contain the login form again, implying login failed
grep 'j_security_check' -q $DIR/curl.out 
if [ 0 == $? ] ; then
    errorMsg "login was not successful"
    exit 2
fi

echo "Login OK"
