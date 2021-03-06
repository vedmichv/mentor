#!/bin/bash

cd $(dirname $0)
git reset --hard HEAD 1>/dev/null 2>&1
git pull -f 1>/dev/null 2>&1

standName=${2}

function getRunning(){
  docker ps -qa --filter label=lab | head -1
}

function status() {
  if [[ -n "$(getRunning)" ]]; then
    echo Running Trainings:
    TRAINING=$(docker inspect $(getRunning) -f '{{.Config.Labels.training}}')
    docker ps -a --filter label=lab \
      --format "table {{.ID}}|{{.Names}}|{{.Status}}|TRAINING|URL" | 
    sed 's/^\([0-9a-f].*\)URL/\1http:\/\/localhost:8081/;s/^\([0-9a-f].*\)TRAINING/\1'${TRAINING}'/' |
    awk -F'|' '{printf "  %-15s %-15s %-15s %-10s %s\n", $1, $2, $3, $4, $5}'
    echo
  fi 
  echo Available Trainings:
  find envs/ -name "*.yaml" | sed 's#.*/##;s#.yaml$##' | awk '{printf "  - %s\t ([user@host] $ ./lab.sh start %s)\n", $1, $1}'
  echo

  echo "To stop running training, please hit this command:"
  echo "[user@host] \$ ./lab.sh stop"
  echo
}

function start() {
  if [ -n "${standName}" ]; then
    docker-compose -f envs/${standName}.yaml pull
    docker-compose -f envs/${standName}.yaml up -d
  fi
}

function stop() {
  if [[ -n "$(getRunning)" ]]; then
    TRAINING=$(docker inspect $(getRunning) -f '{{.Config.Labels.training}}' | sed 's/<no value>//')
    echo ${TRAINING}
    if [ -n "${TRAINING}" ]; then
      docker-compose -f envs/${TRAINING}.yaml down --volumes
    else
     docker-compose -f envs/${standName}.yaml down --volumes
    fi
  else
    docker-compose -f envs/${standName}.yaml down --volumes
  fi
}

case $1 in
  start|up|run)
    start
    ;;
  restart)
    stop
    start
    ;;
  stop|down)
    stop
    ;;
  *) status
esac
