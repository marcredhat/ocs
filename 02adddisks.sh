#each worker gets 3 disks
DISKSIZE=500G

rm -rf /opt/iso
mkdir /opt/iso
j=0
for i in {0..8}
do
#echo "qemu-img create -f raw /opt/iso/disk${i}.img ${DISKSIZE}"
qemu-img create -f raw /opt/iso/disk${i}.img ${DISKSIZE}
        if (( i % 3 == 0 ))
        then
                j=$(($j+1))
        fi

#echo "virsh attach-disk ocp4-worker-${j} /opt/iso/disk${i}.img  sd${i}"
virsh attach-disk ocp4-worker-${j} /opt/iso/disk${i}.img  sd${i}
done
