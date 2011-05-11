#!/bin/bash

logger -p info "Starting ${@} backup"

. /etc/backup-common.sh

backup_mount && rsnapshot ${@}

if [[ "${@}" == "weekly" && -f "/etc/rsnapshot-xenimages.conf" ]]; then
        rsnapshot -c /etc/rsnapshot-xenimages.conf ${@}
fi

backup_umount
