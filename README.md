
## OpenShift Container Storage 4.5.2+ and OpenShift Container Platform 4.6.4+ on one bare metal server (KVM / libvirt / CentOS 7.9)

**Note:** for lab purposes only

## TL;DR

OpenShift Container Storage (OCS) and OpenShift Container Platform (OCP) running on 
one baremetal server (128 GB RAM, 40 CPUs, 4TB disk available to OCS).

The OCP install is fully automated. The OCS install is done using command-line only so it can be automated further. Tested on OCP 4.5 and 4.6.

In the detailed step-by-step example below,
the Local Storage Operator allows us to 
expose 9 disks (total 4TB, 3 storage-dedicated disks on each worker node) as block storage available to OpenShift Container Storage.

OpenShift Container Storage allows us to dynamically provision block, object and file storage.

In the example below, a PVC is created using ocs-storagecluster-ceph-rbd as default OpenShift Container Storage storage class.

```text
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rbd-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-ceph-rbd
```

```text
Result: PV created and bound automatically by OpenShift Container Storage 

[root@ve1301 user]# oc get pvc | grep Bound
cephfs-pvc                     Bound     pvc-148b846a-d319-4ec9-8ef1-52dda0531274   1Gi        RWX            ocs-storagecluster-cephfs     8h
db-noobaa-db-0                 Bound     pvc-deae9eed-3a46-4830-b5a7-18d4826fb2cd   50Gi       RWO            ocs-storagecluster-ceph-rbd   11h
ocs-deviceset-0-data-0-fkccq   Bound     local-pv-c55b2a9d                          600Gi      RWO            localblock                    11h
ocs-deviceset-0-data-1-lwvpr   Bound     local-pv-3fed8002                          600Gi      RWO            localblock                    11h
ocs-deviceset-0-data-2-qp9kt   Bound     local-pv-abc28b0c                          600Gi      RWO            localblock                    11h
ocs-deviceset-2-data-0-6vh5q   Bound     local-pv-db0a9a58                          600Gi      RWO            localblock                    11h
ocs-deviceset-2-data-1-f9h2m   Bound     local-pv-72eaccf                           600Gi      RWO            localblock                    11h
ocs-deviceset-2-data-2-lsdnm   Bound     local-pv-c6f10c36                          600Gi      RWO            localblock                    11h
rbd-pvc                        Bound     pvc-ee2fbc48-bcb9-416b-8f08-b9e67a2ede4b   1Gi        RWO            ocs-storagecluster-ceph-rbd   8h
```


## Authors

- Marc Chisinevski ([@marcredhat](https://github.com/marcredhat))


## Prerequisites

OpenShift Container Platform 4.5 or 4.6 on baremetal

Tested on one baremetal server with min 128GB RAM and 40 CPUs.

Automated OpenShift Container Platform 4 install on baremetal: https://github.com/marcredhat/ocp

## Check that the OpenShift Container Platform is ready

```text
[root@ve1301 user]# virsh list
 Id    Name                           State
----------------------------------------------------
 2     ocp4-lb                        running
 11    ocp4-master-1                  running
 12    ocp4-master-2                  running
 13    ocp4-master-3                  running
 14    ocp4-worker-1                  running
 15    ocp4-worker-2                  running
 16    ocp4-worker-3                  running

[root@ve1301 user]# oc get nodes
NAME                  STATUS   ROLES           AGE   VERSION
master-1.ocp4.local   Ready    master,worker   13h   v1.19.0+9f84db3
master-2.ocp4.local   Ready    master,worker   13h   v1.19.0+9f84db3
master-3.ocp4.local   Ready    master,worker   13h   v1.19.0+9f84db3
worker-1.ocp4.local   Ready    worker          13h   v1.19.0+9f84db3
worker-2.ocp4.local   Ready    worker          13h   v1.19.0+9f84db3
worker-3.ocp4.local   Ready    worker          13h   v1.19.0+9f84db3
```

## Check that masters and workers have the correct minimum CPU and RAM resources:

```text
virsh dominfo ocp4-master-1
Id:             11
Name:           ocp4-master-1
UUID:           5160347a-11f9-4380-8a8b-58ac9048767a
OS Type:        hvm
State:          running
CPU(s):         4
CPU time:       87782.4s
Max memory:     16384000 KiB
Used memory:    16384000 KiB
Persistent:     yes
Autostart:      disable
Managed save:   no
Security model: none
Security DOI:   0

[root@ve1301 user]# virsh dominfo ocp4-worker-1
Id:             14
Name:           ocp4-worker-1
UUID:           e3686d5b-e483-4c01-aa3d-204d8d1242c3
OS Type:        hvm
State:          running
CPU(s):         6
CPU time:       44930.3s
Max memory:     16384000 KiB
Used memory:    16384000 KiB
Persistent:     yes
Autostart:      disable
Managed save:   no
Security model: none
Security DOI:   0
```


## Clean up operators you do not need

Example:

```bash
oc scale --replicas=0 deployment --all -n openshift-monitoring
oc scale --replicas=0 deployment --all -n cluster-samples-operator
oc scale --replicas=0 deployment --all -n  cluster-autoscaler-operator
oc scale --replicas=0 deployment --all -n cluster-node-tuning-operator
oc scale --replicas=0 deployment --all -n cluster-samples-operator
```

## Check disks available on the baremetal server 

We'll be using /dev/sdb1, /dev/sdd1 and  /dev/sdc1

```text
df -h
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs         63G     0   63G   0% /dev
tmpfs            63G     0   63G   0% /dev/shm
tmpfs            63G   44M   63G   1% /run
tmpfs            63G     0   63G   0% /sys/fs/cgroup
/dev/sda1       745G   11G  735G   2% /
/dev/sdb1       1.9T  1.9G  1.9T   1% /data/1
/dev/sdd1       1.9T   33M  1.9T   1% /data/3
/dev/sdc1       1.9T   73M  1.9T   1% /data/2
/dev/sda3       1.1T   49G  1.1T   5% /var
tmpfs            13G     0   13G   0% /run/user/5080
```

## On the baremetal server, create 9 disks

We'll attach 3 disks to each OCP worker node.

```bash
cd /data/1
qemu-img create -f raw disk1.img 600G
qemu-img create -f raw disk2.img 600G
qemu-img create -f raw disk3.img 600G



cd /data/2
qemu-img create -f raw disk4.img 600G
qemu-img create -f raw disk5.img 600G
qemu-img create -f raw disk6.img 600G



cd /data/3
qemu-img create -f raw disk7.img 600G
qemu-img create -f raw disk8.img 600G
qemu-img create -f raw disk9.img 600G
```

## Attach 3 disks to each OCP worker node

```bash
virsh attach-disk ocp4-worker-1 /data/1/disk1.img  sdl
virsh attach-disk ocp4-worker-1 /data/1/disk2.img  sdm
virsh attach-disk ocp4-worker-1 /data/1/disk3.img  sdn

virsh attach-disk ocp4-worker-2 /data/2/disk4.img  sdo
virsh attach-disk ocp4-worker-2 /data/2/disk5.img  sdp
virsh attach-disk ocp4-worker-2 /data/2/disk6.img  sdq

virsh attach-disk ocp4-worker-3 /data/3/disk7.img  sdr
virsh attach-disk ocp4-worker-3 /data/3/disk8.img  sds
virsh attach-disk ocp4-worker-3 /data/3/disk9.img  sdt

```

## On each worker nodes, list the disks

Copy the 9 disk name, we'll use them in a further step when we create the LocalVolume 

In my case, the disks listed by the command below are:

```text
        - /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1-0-0-4 
        - /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1-0-0-5 
        - /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1-0-0-6 
        - /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi2-0-0-0 
        - /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi2-0-0-1 
        - /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi2-0-0-2 
        - /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi2-0-0-3 
        - /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi2-0-0-4 
        - /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi2-0-0-5 
```

Here is the command to the list the disks on each worker node:

```bash
wget https://raw.githubusercontent.com/marcredhat/ocs/main/03listdisks.sh
chmod +x ./03listdisks.sh
./03listdisks.sh
```

Result: 

```text
Warning: Permanently added 'worker-1.ocp4.local,192.168.122.116' (ECDSA) to the list of known hosts.
total 0
lrwxrwxrwx. 1 root root  9 Nov 23 05:49 scsi-0QEMU_QEMU_HARDDISK_drive-scsi1-0-0-4 -> ../../sdb
lrwxrwxrwx. 1 root root  9 Nov 23 05:49 scsi-0QEMU_QEMU_HARDDISK_drive-scsi1-0-0-5 -> ../../sda
lrwxrwxrwx. 1 root root  9 Nov 23 05:49 scsi-0QEMU_QEMU_HARDDISK_drive-scsi1-0-0-6 -> ../../sdc
The authenticity of host 'worker-2.ocp4.local (192.168.122.117)' can't be established.
Warning: Permanently added 'worker-2.ocp4.local,192.168.122.117' (ECDSA) to the list of known hosts.
total 0
lrwxrwxrwx. 1 root root  9 Nov 23 05:49 scsi-0QEMU_QEMU_HARDDISK_drive-scsi2-0-0-0 -> ../../sda
lrwxrwxrwx. 1 root root  9 Nov 23 05:49 scsi-0QEMU_QEMU_HARDDISK_drive-scsi2-0-0-1 -> ../../sdc
lrwxrwxrwx. 1 root root  9 Nov 23 05:49 scsi-0QEMU_QEMU_HARDDISK_drive-scsi2-0-0-2 -> ../../sdb
The authenticity of host 'worker-3.ocp4.local (192.168.122.210)' can't be established.
Warning: Permanently added 'worker-3.ocp4.local,192.168.122.210' (ECDSA) to the list of known hosts.
total 0
lrwxrwxrwx. 1 root root  9 Nov 23 05:49 scsi-0QEMU_QEMU_HARDDISK_drive-scsi2-0-0-3 -> ../../sdb
lrwxrwxrwx. 1 root root  9 Nov 23 05:49 scsi-0QEMU_QEMU_HARDDISK_drive-scsi2-0-0-4 -> ../../sda
lrwxrwxrwx. 1 root root  9 Nov 23 05:49 scsi-0QEMU_QEMU_HARDDISK_drive-scsi2-0-0-5 -> ../../sdc
```

## Create the openshift-local-storage namespace

```text
oc create -f https://raw.githubusercontent.com/marcredhat/ocs/main/04localstoragenamespace.yaml
namespace/openshift-local-storage created
```

## Create the local-storage OperatorGroup

```text
oc create -f https://raw.githubusercontent.com/marcredhat/ocs/main/05localstorageoperatorgroup.yaml
operatorgroup.operators.coreos.com/local-storage created
```

## Creaet the local-storage-operator Subscription

```text
oc create -f https://raw.githubusercontent.com/marcredhat/ocs/main/06localstoragesubscription.yaml
subscription.operators.coreos.com/local-storage-operator created
```

##  Label the OCP worker nodes that will be used for storage

```text
wget https://raw.githubusercontent.com/marcredhat/ocs/main/07labelnodes.sh
chmod +x ./07labelnodes.sh
./07labelnodes.sh
node/worker-1.ocp4.local labeled
node/worker-2.ocp4.local labeled
node/worker-3.ocp4.local labeled
```


## Create the LocalVolume using the 9 disks that we attached to the worker nodes 

Ensure that you are in the correct namespace.

```bash
oc project openshift-local-storage
```

```text
oc create -f https://raw.githubusercontent.com/marcredhat/ocs/main/08localvolume.yaml
localvolume.local.storage.openshift.io/local-block created
```


## Check that all pods are running are the openshift-local-storage namespace

```text
oc get pods
NAME                                      READY   STATUS    RESTARTS   AGE
local-block-local-diskmaker-kr9wk         1/1     Running   0          44s
local-block-local-diskmaker-mg8ml         1/1     Running   0          43s
local-block-local-diskmaker-p55nv         1/1     Running   0          42s
local-block-local-provisioner-fjmdb       1/1     Running   0          46s
local-block-local-provisioner-vqjj7       1/1     Running   0          45s
local-block-local-provisioner-xp5g6       1/1     Running   0          45s
local-storage-operator-7848c8f869-g5f9n   1/1     Running   0          9m7s
```

## Check that the LocalStorage PVs are Available

```text
oc get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
local-pv-3cf094c2   600Gi      RWO            Delete           Available           localblock              3m46s
local-pv-3fed8002   600Gi      RWO            Delete           Available           localblock              3m50s
local-pv-72eaccf    600Gi      RWO            Delete           Available           localblock              3m45s
local-pv-abc28b0c   600Gi      RWO            Delete           Available           localblock              3m50s
local-pv-c55b2a9d   600Gi      RWO            Delete           Available           localblock              3m51s
local-pv-c6f10c36   600Gi      RWO            Delete           Available           localblock              3m44s
local-pv-db0a9a58   600Gi      RWO            Delete           Available           localblock              3m45s
local-pv-eb2f5643   600Gi      RWO            Delete           Available           localblock              3m46s
local-pv-fb4445dd   600Gi      RWO            Delete           Available           localblock              3m47s
```

## Openshift Container Storage

## Create the openshift-storage namespace

```text
oc create -f https://raw.githubusercontent.com/marcredhat/ocs/main/09ocsnamespace.yaml
namespace/openshift-storage created
```

## Create the openshift-storage-operatorgroup OperatorGroup

```text
oc create -f https://raw.githubusercontent.com/marcredhat/ocs/main/10ocsoperatorgroup.yaml
operatorgroup.operators.coreos.com/openshift-storage-operatorgroup created
```

## Create the ocs-operator Subscription

oc create -f https://raw.githubusercontent.com/marcredhat/ocs/main/11ocssubscription.yaml
subscription.operators.coreos.com/ocs-operator created


## Check that the Noobaa, OCS and Rook-Ceph Operator pods are running 


Ensure that you are in the correct namespace.

```bash
oc project openshift-storage
```

```text
oc get pods
NAME                                 READY   STATUS    RESTARTS   AGE
noobaa-operator-654448bf59-ksxjd     1/1     Running   0          2m52s
ocs-operator-6b6bf9d5c9-w75k4        1/1     Running   1          2m59s
rook-ceph-operator-6689b96c6-gw5wc   1/1     Running   1          2m58s
```

For each set of 3 OSDs increment the count. We have 9 OSD so count is 3.

```bash
oc create -f https://raw.githubusercontent.com/marcredhat/ocs/main/12ocsstoragecluster.yaml
```

## Install the Ceph tools

```bash
wget https://raw.githubusercontent.com/marcredhat/ocs/main/13installcephtools.sh
chmod +x ./13installcephtools.sh
./13installcephtools.sh
```

## Create PVCs to check that block and file storage is automatically provisioned by the OCS

```bash
oc create -f https://raw.githubusercontent.com/marcredhat/ocs/main/14testCephRBD.yaml
oc create -f https://raw.githubusercontent.com/marcredhat/ocs/main/15testCephFS.yaml
```

## Make ocs-storagecluster-ceph-rbd the default storage class

```
wget https://raw.githubusercontent.com/marcredhat/ocs/main/16setdefaultstorageclass.sh
chmod +x ./16setdefaultstorageclass.sh
./16setdefaultstorageclass.sh
```

## Check that all PVCs are bound

```text
oc get pvc | grep Bound

cephfs-pvc                     Bound     pvc-148b846a-d319-4ec9-8ef1-52dda0531274   1Gi        RWX            ocs-storagecluster-cephfs     7h55m
db-noobaa-db-0                 Bound     pvc-deae9eed-3a46-4830-b5a7-18d4826fb2cd   50Gi       RWO            ocs-storagecluster-ceph-rbd   11h
ocs-deviceset-0-data-0-fkccq   Bound     local-pv-c55b2a9d                          600Gi      RWO            localblock                    11h
ocs-deviceset-0-data-1-lwvpr   Bound     local-pv-3fed8002                          600Gi      RWO            localblock                    10h
ocs-deviceset-0-data-2-qp9kt   Bound     local-pv-abc28b0c                          600Gi      RWO            localblock                    10h
ocs-deviceset-2-data-0-6vh5q   Bound     local-pv-db0a9a58                          600Gi      RWO            localblock                    10h
ocs-deviceset-2-data-1-f9h2m   Bound     local-pv-72eaccf                           600Gi      RWO            localblock                    10h
ocs-deviceset-2-data-2-lsdnm   Bound     local-pv-c6f10c36                          600Gi      RWO            localblock                    10h
rbd-pvc                        Bound     pvc-ee2fbc48-bcb9-416b-8f08-b9e67a2ede4b   1Gi        RWO            ocs-storagecluster-ceph-rbd   7h55m
```

## Check Ceph health 

```bash
wget https://raw.githubusercontent.com/marcredhat/ocs/main/17checkcephhealth.sh
chmod +x ./17checkcephhealth.sh
./17checkcephhealth.sh
```

```text
[root@ve1301 user]# oc rsh rook-ceph-tools-f5494bcdc-8scbf
sh-4.4# ceph status
  cluster:
    id:     d2386842-1ee7-4550-82a8-3015c27ad16c
    health: HEALTH_WARN
            Degraded data redundancy: 103/309 objects degraded (33.333%), 56 pgs degraded, 176 pgs undersized
            1 daemons have recently crashed

  services:
    mon: 3 daemons, quorum a,b,c (age 21s)
    mgr: a(active, since 11h)
    mds: ocs-storagecluster-cephfilesystem:1 {0=ocs-storagecluster-cephfilesystem-a=up:active}
    osd: 6 osds: 2 up (since 10h), 2 in (since 10h)

  task status:
    scrub status:
        mds.ocs-storagecluster-cephfilesystem-a: idle

  data:
    pools:   10 pools, 176 pgs
    objects: 103 objects, 47 KiB
    usage:   2.2 GiB used, 1.2 TiB / 1.2 TiB avail
    pgs:     103/309 objects degraded (33.333%)
             120 active+undersized
             56  active+undersized+degraded


ceph osd tree
ID CLASS WEIGHT  TYPE NAME                        STATUS REWEIGHT PRI-AFF
-1       1.17178 root default
-4       0.58589     rack rack0
-3       0.58589         host worker-1-ocp4-local
 0   hdd 0.58589             osd.0                    up  1.00000 1.00000
-8       0.58589     rack rack2
-7       0.58589         host worker-3-ocp4-local
 3   hdd 0.58589             osd.3                    up  1.00000 1.00000
 1             0 osd.1                              down        0 1.00000
 2             0 osd.2                              down        0 1.00000
 4             0 osd.4                              down        0 1.00000
 5             0 osd.5                              down        0 1.00000
 ```
 
