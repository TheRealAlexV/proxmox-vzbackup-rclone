# proxmox-vzbackup-rclone

This is a vzbackup hook script that backups up your proxmox vms, containers and pve configs to remote storage such as google drive using proxmox's native vzbackup tool and rclone.

rclone is a command line tool that allows you to sync files from your local disk, to a cloud storage device. RClone is most popular with Google Drive but it can be used for other cloud providers. RClone is based off another tool called RSync but with RClone you get so much more functionality built in such as encryption. See https://rclone.org/.

Backups are stored in the rclone remote and organized into YEAR/MONTH/DAY directories to ease the managagement of the backup files. The backup script also prunes local backups after a configurable amount of days and has an easy to use script to pull old backups from the remote. 

This was built and tested with Google Drive only, however it should work with other providers as well. I recomend Google Drive though because you can get a Google Apps business account for $12 a month which gets you **Unlimited** drive space.

## Quickstart

1. SSH or Log into your Proxmox host. Install rclone with `apt-get update;apt-get install rclone;`.
Setup an rclone remote and encrypt that remote if so desired. Further information on configuring rclone can be found here:
 - Adding google drive to rclone: https://rclone.org/drive/
 - Encryping your rclone contents: https://rclone.org/crypt/

When setting up the encryption, I DO NOT reccomend you encrypt the filenames and directory names. Doing so will break the ability to easily pull down backups from the remmote.

2. SSH or Log into your Proxmox host as root and clone the repo. I recomend you store it in the `/root` dir so that it also gets backed up.
```
apt-get install git
cd /root
git clone https://github.com/TheRealAlexV/proxmox-vzbackup-rclone.git
chmod +x /root/proxmox-vzbackup-rclone/vzbackup-rclone.sh
```

3. Edit vzbackup-rclone.sh and set both `$dumpdir` and `$MAX_AGE` at the top of the file. 

4. Open /etc/vzdump.conf, uncomment the `script:` line and set that to `/root/proxmox-vzbackup-rclone/vzbackup-rclone.sh`:
```
script:/root/proxmox-vzbackup-rclone/vzbackup-rclone.sh
```

5. You're finished. Kicking off a manual or scheduled backup will automatically trigger the rclone backup. To verify this, you can kickoff a manual backup and watch the proxmox console log output.

## Rehydrate (restore) old backups

At some point, it'll be very likely that you'll need to pull old backups from your rclone remote that have been removed from the local proxmox server. This can be done by passing the `rehydrate` parameter to the vzbackup-rclone.sh script:
`$ ~/proxmox-vzbackup-rclone/vzbackup-rclone.sh rehydrate`
```
Please enter the date you want to rehydrate in the following format: YYYY/MM/DD
For example, today would be: 2020/06/02
Rehydrate Date => 2020/06/02

2020/06/02 19:41:28 INFO  : Local file system at /mnt/pve/pvebackups01/dump: Waiting for checks to finish
2020/06/02 19:41:28 INFO  : Local file system at /mnt/pve/pvebackups01/dump: Waiting for transfers to finish
2020/06/02 19:41:29 INFO  : proxmox_backup_pve-01_2020-06-02.18.42.54.tar.gz: Copied (new)
2020/06/02 19:41:29 INFO  : proxmox_backup_pve-01_2020-06-02.18.42.29.tar.gz: Copied (new)
2020/06/02 19:41:29 INFO  : proxmox_backup_pve-01_2020-06-02.18.29.32.tar.gz: Copied (new)
2020/06/02 19:41:29 INFO  : proxmox_backup_pve-01_2020-06-02.18.43.13.tar.gz: Copied (new)
2020/06/02 19:41:29 INFO  : vzdump-lxc-121-2020_06_02-18_42_23.tar.zst: Copied (new)
2020/06/02 19:41:29 INFO  : vzdump-lxc-121-2020_06_02-18_29_25.tar.zst: Copied (new)
2020/06/02 19:41:29 INFO  : vzdump-lxc-121-2020_06_02-18_43_06.tar.zst: Copied (new)
2020/06/02 19:41:29 INFO  : vzdump-lxc-121-2020_06_02-18_42_48.tar.zst: Copied (new)
2020/06/02 19:41:29 INFO  :
Transferred:       15.591M / 15.591 MBytes, 100%, 4.298 MBytes/s, ETA 0s
Errors:                 0
Checks:                 0 / 0, -
Transferred:            8 / 8, 100%
Elapsed time:        3.6s
```

You can do this over as many days as you need. Just make sure your backup storage has the room to hold everything. You can then do a restore like you normally would from the webui or using the vzdump cli.
