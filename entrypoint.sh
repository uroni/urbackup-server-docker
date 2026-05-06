#!/bin/bash
set -e

if [[ -n "$TMPDIR" ]]; then
    if [ -d "$TMPDIR" ]; then
        rm -f "$TMPDIR"/*
    fi
else
    for dir in /tmp /var/tmp; do
        if [ -d "$dir" ]; then
            rm -f "$dir"/*
        fi
    done
fi

# Copy www-folder back, if folder is bind-mounted
cp -R /web-backup/* /usr/share/urbackup
# Specifying backup-folder location
echo "/backups" > /var/urbackup/backupfolder
# Set ZFS dataset if ENV variable is not empty
if [[ -v ZFS_IMAGE ]]; then
	echo "$ZFS_IMAGE" > /etc/urbackup/dataset
	zfs mount -R "$ZFS_IMAGE"
fi
if [[ -v ZFS_FILES ]]; then
	echo "$ZFS_FILES" > /etc/urbackup/dataset_file
	zfs mount -R "$ZFS_FILES"
fi
# Giving the user and group "urbackup" the provided UID/GID
if [[ $PUID != "" ]]
then
	usermod -u $PUID -o urbackup
else
	usermod -u 101 -o urbackup
fi
if [[ $PGID != "" ]]
then
	groupmod -g $PGID -o urbackup
else
	groupmod -g 101 -o urbackup
fi

# Check if /backups and /var/urbackup is writable by urbackup user and conditionally chown
su -s /bin/bash -c "test -w /backups" urbackup || chown urbackup:urbackup /backups
su -s /bin/bash -c "test -w /var/urbackup" urbackup || chown urbackup:urbackup /var/urbackup

exec urbackupsrv "$@"
