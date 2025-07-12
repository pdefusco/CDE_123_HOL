#!/bin/sh

cde_user=$1
max_participants=$2
cdp_data_lake_storage=$3

cde_user_formatted=${cde_user//[-._]/}
d=$(date)
fmt="%-30s %s\n"

echo "##########################################################"
printf "${fmt}" "CDE HOL deployment launched."
printf "${fmt}" "launch time:" "${d}"
printf "${fmt}" "performed by CDP User:" "${cde_user}"
echo "##########################################################"

echo "CREATE FILE RESOURCE"
cde resource delete --name cde123-hol-setup-fs
cde resource create --name cde123-hol-setup-fs --type files
cde resource upload --name cde123-hol-setup-fs --local-path setup/utils.py --local-path setup/setup.py
echo "CREATE PYTHON RESOURCE"
cde resource delete --name cde123-hol-setup-py
cde resource create --type python-env --name datagen-hol-setup-py
cde resource upload --name datagen-hol-setup-py --local-path setup/requirements.txt

function loading_icon_env() {
  local loading_animation=( '—' "\\" '|' '/' )

  echo "${1} "

  tput civis
  trap "tput cnorm" EXIT

  while true; do
    build_status=$(cde resource describe --name datagen-hol-setup-py | jq -r '.status')
    if [[ $build_status == $"ready" ]]; then
      echo "Setup Python Env Build Completed."
      break
    else
      for frame in "${loading_animation[@]}" ; do
        printf "%s\b" "${frame}"
        sleep 1
      done
    fi
  done
  printf " \b\n"
}

loading_icon_env "Python Env Build in Progress"

echo "CREATE AND RUN SETUP JOB"
cde job delete --name cde123-hol-setup-job
cde job create --name cde123-hol-setup-job --type spark --mount-1-resource cde123-hol-setup-fs --application-file setup.py --python-env-resource-name datagen-hol-setup-py --arg $max_participants --arg $cdp_data_lake_storage
cde job run --name cde123-hol-setup-job --executor-memory "2g" --executor-cores 2

function loading_icon_job() {
  local loading_animation=( '—' "\\" '|' '/' )

  echo "${1} "

  tput civis
  trap "tput cnorm" EXIT

  while true; do
    job_status=$(cde run list --filter 'job[like]%cde123-hol-setup-job' | jq -r '[last] | .[].status')
    if [[ $job_status == "succeeded" ]]; then
      echo "Setup Job Execution Completed"
      break
    else
      for frame in "${loading_animation[@]}" ; do
        printf "%s\b" "${frame}"
        sleep 1
      done
    fi
  done
  printf " \b\n"
}

loading_icon_job "Setup Job in Progress"

echo "##########################################################"
printf "${fmt}" "CDE ${cde_demo} HOL deployment completed."
printf "${fmt}" "completion time:" "${e}"
printf "${fmt}" "please visit CDE Job Runs UI to view in-progress demo"
echo "##########################################################"
