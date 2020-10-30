# proxmox-vzbackup-rclone

This is a vzbackup hook script that backups up your proxmox vms, containers and pve configs to remote storage such as google drive using proxmox's native vzbackup tool and rclone.

rclone is a command line tool that allows you to sync files from your local disk, to a cloud storage device. RClone is most popular with Google Drive but it can be used for other cloud providers. RClone is based off another tool called RSync but with RClone you get so much more functionality built in such as encryption. See https://rclone.org/.

Backups are stored in the rclone remote and organized into YEAR/MONTH/DAY directories to ease the management of the backup files. The backup script also prunes local backups after a configurable amount of days. The script DOES NOT prune backups stored on the remote. You will need to manage that separately if you do not have unlimited space. There is also an easy to use script to pull old backups from the remote so that you can restore them like you normally would through the webui or vzdump tool. 

This was built and tested with Google Drive only, however it should work with other providers as well. I recommend Google Drive though because you can get a Google Apps business account for $12 a month which gets you **Unlimited** drive space.

## Quickstart

1. SSH or Log into your Proxmox host. Install rclone with `apt-get update;apt-get install rclone;`.
Setup an rclone remote and encrypt that remote if so desired. Further information on configuring rclone can be found here:
 - Adding google drive to rclone: https://rclone.org/drive/
 - Encryping your rclone contents: https://rclone.org/crypt/

When setting up the encryption, I DO NOT reccomend you encrypt the filenames and directory names. Doing so will break the ability to easily pull down backups from the remmote.

2. SSH or Log into your Proxmox host as root and clone the repo. I recommend you store it in the `/root` dir so that it also gets backed up.
```
apt-get install git
cd /root
git clone https://github.com/TheRealAlexV/proxmox-vzbackup-rclone.git
chmod +x /root/proxmox-vzbackup-rclone/vzbackup-rclone.sh
```

3. Edit vzbackup-rclone.sh and set `$dumpdir`, `$MAX_AGE` and `$DRIVE_NAME` at the top of the file. 

4. Open /etc/vzdump.conf, uncomment the `script:` line and set that to `/root/proxmox-vzbackup-rclone/vzbackup-rclone.sh`:
```
script:/root/proxmox-vzbackup-rclone/vzbackup-rclone.sh
```

5. You're finished. Kicking off a manual or scheduled backup will automatically trigger the rclone backup. To verify this, you can kickoff a manual backup and watch the proxmox console log output.

### Example webui console output from a successful vzbackup run:

```
INFO: starting new backup job: vzdump 121 --compress zstd --node pve-03 --remove 0 --mode snapshot --storage pvebackups01
INFO: Deleting backups older than 3 days.
INFO: filesystem type on dumpdir is 'ceph' -using /var/tmp/vzdumptmp1890531 for temporary files
INFO: Starting Backup of VM 121 (lxc)
INFO: Backup started at 2020-06-02 20:19:04
INFO: status = running
INFO: CT Name: mini-test
INFO: backup mode: snapshot
INFO: ionice priority: 7
INFO: create storage snapshot 'vzdump'
/dev/rbd12
INFO: creating archive '/mnt/pve/pvebackups01/dump/vzdump-lxc-121-2020_06_02-20_19_04.tar.zst'
INFO: Total bytes written: 9021440 (8.7MiB, 6.6MiB/s)
INFO: archive file size: 2MB
INFO: Backing up /mnt/pve/pvebackups01/dump/vzdump-lxc-121-2020_06_02-20_19_04.tar.zst to remote storage
INFO: rcloning /mnt/pve/pvebackups01/dump/rclone/2020/06/02
INFO: 2020/06/02 20:19:12 INFO  : vzdump-lxc-121-2020_06_02-20_19_04.tar.zst: Copied (new)
INFO: 2020/06/02 20:19:12 INFO  : 
INFO: Transferred:   	    2.986M / 2.986 MBytes, 100%, 546.989 kBytes/s, ETA 0s
INFO: Errors:                 0
INFO: Checks:                 0 / 0, -
INFO: Transferred:            1 / 1, 100%
INFO: Elapsed time:        5.5s
INFO: remove vzdump snapshot
Removing snap: 100% complete...done.
INFO: Finished Backup of VM 121 (00:00:09)
INFO: Backup finished at 2020-06-02 20:19:13
INFO: Backing up main PVE configs
INFO: Tar files
INFO: Compressing files
INFO: /var/tmp/proxmox-mqnIdwRD/proxmoxetc.2020-06-02.20.19.13.tar
INFO: /var/tmp/proxmox-mqnIdwRD/proxmoxpve.2020-06-02.20.19.13.tar
INFO: /var/tmp/proxmox-mqnIdwRD/proxmoxroot.2020-06-02.20.19.13.tar
INFO: '/var/tmp/proxmox-mqnIdwRD/proxmox_backup_pve-03_2020-06-02.20.19.13.tar.gz' -> '/mnt/pve/pvebackups01/dump/proxmox_backup_pve-03_2020-06-02.20.19.13.tar.gz'
INFO: rcloning /var/tmp/proxmox-mqnIdwRD/proxmox_backup_pve-03_2020-06-02.20.19.13.tar.gz
INFO: 2020/06/02 20:19:17 INFO  : proxmox_backup_pve-03_2020-06-02.20.19.13.tar.gz: Copied (new)
INFO: 2020/06/02 20:19:17 INFO  : proxmox_backup_pve-03_2020-06-02.20.19.13.tar.gz: Deleted
INFO: 2020/06/02 20:19:17 INFO  : 
INFO: Transferred:   	  935.429k / 935.429 kBytes, 100%, 228.905 kBytes/s, ETA 0s
INFO: Errors:                 0
INFO: Checks:                 1 / 1, 100%
INFO: Transferred:            1 / 1, 100%
INFO: Elapsed time:          4s
INFO: Cleaning up
INFO: Backup job finished successfully
TASK OK
```

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
