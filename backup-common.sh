 
#!/bin/bash

## DISK="/dev/disk/by-path/pci-0000:00:1a.7-usb-0:1:1.0-scsi-0:0:0:0-part1"
#DISK="/dev/disk/by-path/pci-0000:00:1d.7-usb-0:3:1.0-scsi-0:0:0:0-part1"
#DISK="/dev/disk/by-path/pci-0000:00:1d.7-usb-0:6:1.0-scsi-0:0:0:0-part1"
#DISK="/dev/sdb1"

DISK=$(ls /dev/disk/by-path/pci-0000:00:1d.7-usb-*-part1 | head -n1)

# Target name
TARGET="backup"

# Mount point
BACKUP="/mnt/.backup"

# Password for crypted volume
KEYFILE="/etc/backup-passwd"

backup_crypt_open() {

        [ -b "/dev/disk/by-label/$TARGET" ] && return 0;

        if [ ! -f "$KEYFILE" ]; then 
                echo "Missing keyfile $KEYFILE"
                exit 1
        fi

        if [ ! -b $DISK ]; then
                echo "Disk is missing: $DISK"
                exit 1
        fi

        if cryptsetup isLuks "$DISK" 2> /dev/null; then
                ## Set up
                cryptsetup luksOpen "$DISK" "$TARGET" < $KEYFILE > /dev/null 2>&1
        else
                echo "Disk $DISK is not cyrpted luks partition."
                exit 1
        fi
}

backup_crypt_close() {
        [ -b "/dev/disk/by-label/$TARGET" ] && return 1;
        cryptsetup luksClose "$TARGET"
}

backup_mount() {
        if [ ! "$(grep " $BACKUP " /proc/mounts)" ]; then
                backup_crypt_open
                if [ -b "/dev/disk/by-label/$TARGET" ]; then
                        echo "No mountable disk $TARGET"
                        return 1
                fi
                mount "$BACKUP" || (
                        logger "Could not mount backup dir $BACKUP"
                        echo "Could not mount $BACKUP"
                        return 1
                )
        fi
}

backup_umount() {
        if grep -q " $BACKUP " /proc/mounts; then
                umount $BACKUP
                backup_crypt_close
        fi
}
