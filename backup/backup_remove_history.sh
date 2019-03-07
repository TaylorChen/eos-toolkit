#!/bin/bash

current_home=$(cd `dirname $0`;pwd)
work_home=$(cd ${current_home};cd ../;pwd)
get_config="${work_home}/config/config.sh"
logger="python ${work_home}/utils/logger.py"
backup_days=$(${get_config} "backup_max_days")
backup_folder=$(${get_config} "backup_home")

indexes_folder="${backup_folder}/indexes"
chunks_folder="${backup_folder}/chunks"
tmp_folder="${backup_folder}/tmp"

latest_chunks_names_tmp="${tmp_folder}/latest_chunks_tmp"
latest_chunks_names="${tmp_folder}/latest_chunks"

log() {
    ${logger} -m "$@"
}

get_history_indexes() {
    find ${indexes_folder} -ctime +${backup_days} -type f -wholename "${indexes_folder}/*"
}

get_latest_indexes() {
    find ${indexes_folder} -ctime -${backup_days} -type f -wholename "${indexes_folder}/*"
}

delete_history_chunks() {
    for chunks_name in `ls -l ${chunks_folder}| egrep '[0-9][a-z]+' | awk '{print $9}'`
    do
      is_used=$(grep ${chunks_name} ${latest_chunks_names})
      if [ "${is_used}" == "" ];then
        rm -f "${chunks_folder}/${chunks_name}"
        log "remove ${chunks_name}"
      fi
    done
}

clear_history_chunks() {
    latest_indexes=`get_latest_indexes`
    if [ "${latest_indexes}" == "" ];then
        return
    fi
    if [ ! -d ${tmp_folder} ];then
        mkdir ${tmp_folder}
    fi
    cd ${tmp_folder}
    find ${tmp_folder} -type f -wholename "${tmp_folder}/*.yaml" | xargs rm -f
    find ${tmp_folder} -type f -wholename "${tmp_folder}/*.yaml.gz" | xargs rm -f
    > ${latest_chunks_names}
    > ${latest_chunks_names_tmp}

    find ${indexes_folder} -ctime -${backup_days} -type f -wholename "${indexes_folder}/*" | xargs -I{} cp -f {} "${tmp_folder}/"
    for index_file in $(ls *.yaml.gz)
    do
        gunzip ${index_file}
    done
    for index_file in $(ls *.yaml)
    do
        grep 'contentSHA: ' ${index_file} | sed 's/.*contentSHA: //' >> ${latest_chunks_names_tmp}
    done
    sort -u ${latest_chunks_names_tmp} > ${latest_chunks_names}
    delete_history_chunks
}

clear_history_indexes() {
    history_indexes=`get_history_indexes`
    if [ "${history_indexes}" == "" ];then
        return
    fi
    log "clear history indexes: ${history_indexes}"
    find ${indexes_folder} -ctime +${backup_days} -type f -wholename "${indexes_folder}/*" | xargs rm -f
}

remove_backup_history() {
    clear_history_indexes
    clear_history_chunks
}

remove_backup_history
