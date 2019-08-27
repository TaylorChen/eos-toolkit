#!/bin/bash

pitreos="/mnt/eosbp/command/pitreos"

init_config() {
    backup_home=$(cd `dirname $0`;pwd)
    work_home=$(cd ${backup_home};cd ../;pwd)
    get_config="${work_home}/config/config.sh"
    api=$(${get_config} "local_api")
    eos_home=$(${get_config} "eos_home")
    data_home="${eos_home}/data"

    stop_command="${work_home}/node/stop.sh"
    start_command="${work_home}/node/start.sh"

    default_log=$(${get_config} "monitor_log_file")
    backup_status="${backup_home}/$(${get_config} 'backup_status_file')"

    log_file="${eos_home}/logs/${default_log}"
    notify_tool="python ${work_home}/utils/notify.py"
    logger="python ${work_home}/utils/logger.py"
    hostname=$(hostname)
}

log() {
    ${logger} -m "$@"
}

notify() {
    log "$@"
    ${notify_tool} -m "[[ ${hostname} ]] \n$@"
}

check_api() {
    code=`curl -I -m 10 -o /dev/null -s -w %{http_code} "${api}/v1/chain/get_info"`
    if [ "${code}" != 200 ];then
        notify "backup $1 fail\nplease check api:${api}"
    fi
}

init_backup_status() {
    log "backup start...."
    echo $(date "+%s") > ${backup_status}
}

clear_backup_status() {
    clear_backup_status_command="rm -f ${backup_status}"
    log "${clear_backup_status_command}"
    ${clear_backup_status_command}
}

backup() {
    ${stop_command}
    if [ $? != 0 ]; then
        notify "stop for backup failed"
        clear_backup_status
        exit 1
    fi
    ${pitreos} backup ${data_home} -s "file:///mnt/.pitreos/backups" 2>&1 >> ${log_file}
    if [ $? == 0 ]; then
        log "backup success"
    else
        notify "backup failed."
    fi
    ${start_command}
    if [ $? != 0 ]; then
        notify "restart for backup failed"
    else
        clear_backup_status
    fi
}

main() {
    init_config
    init_backup_status
    check_api "start"
    backup
    sleep 60s
    check_api "end"
}

main
