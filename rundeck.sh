#!/bin/bash

#usage: runjob.sh <server URL | - > <job ID>

PROJECT=$1
JOB_NAME=$2
RUNDECK_HOST=http://10.30.182.171/rundeck
API_VERSION='20'

user="admin"
pass="admin"

function echodate() { date '+%Y-%m-%d %H:%M:%S'; }
function echoinfo() { echo "`echodate` [INFO] $*"; }
function echoerro() { echo "`echodate` [ERRO] $*"; }

### Valida parametros
[ $# != 2 ] && echo "Use: `basename $0` <project_name> <job_name>" && exit 1

DIR=$(cd `dirname $0` && pwd)

function rundeck_login() {

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
  $CURL -d j_username=$user -d j_password=$pass $loginurl > $DIR/curl.out

  if [ 0 != $? ] ; then
      echoerro "failed login request to ${loginurl}"
      exit 2
  fi

  # make sure result doesn't contain the login form again, implying login failed
  grep 'j_security_check' $DIR/curl.out
  if [ 0 == $? ] ; then
      echoerro "login was not successful"
      exit 2
  fi
}

function rundeck_getID(){
  if [ -f $DIR/cookies ]; then
    JOB_ID=$(curl -s -b $DIR/cookies -H accept:application/json $RUNDECK_HOST/api/14/project/$1/jobs \
            | python -m json.tool \
            | tr -d '\n' \
            | sed 's/{/{\n/g' \
            | tr -s " " \
            | grep $2 \
            | sed 's/.*"id": "//g ; s/",.*//g')

    # todo: melhorar tratamento de erro
    echo $JOB_ID | grep -i -q "error" 2>1 /dev/null
    if [ $? == 0 ] ; then
      echoerro "login was not successful"
      exit 1
    fi
    #[ $JOB_ID ] && echo $JOB_ID
    echo $JOB_ID
  else
    echoerro "cookie não existe"
  fi
}

function rundeck_runJob() {
  curl -s -X POST -H accept:application/json -b $DIR/cookies $RUNDECK_HOST/api/$API_VERSION/job/$1/executions \
    | python -m json.tool
}

# Iniciando login
echoinfo "[LOGIN] Criando cookie..."
rundeck_login $RUNDECK_HOST
echo

# Pegando ID do JOB"
echoinfo "[ID] Get job id"
JID=$(rundeck_getID $PROJECT $JOB_NAME)
echo $JID

# Running job by id
echoinfo "[RUN] Running JOB $JOB_NAME"
rundeck_runJob $JID
