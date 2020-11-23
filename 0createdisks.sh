
for i in '1c' '1d' '1e' '1f' '1g' '1h' '1i' '1j' '1k'
do
qemu-img create -f raw /opt/iso/disk${i}.img 200G
done


virsh attach-disk ocp4-worker-1 /opt/iso/diskc.img  sdl
virsh attach-disk ocp4-worker-1 /opt/iso/diskd.img  sdm
virsh attach-disk ocp4-worker-1 /opt/iso/diske.img  sdn
virsh attach-disk ocp4-worker-2 /opt/iso/diskf.img  sdo
virsh attach-disk ocp4-worker-2 /opt/iso/diskg.img  sdp
virsh attach-disk ocp4-worker-2 /opt/iso/diskh.img  sdq
virsh attach-disk ocp4-worker-3 /opt/iso/diski.img  sdr
virsh attach-disk ocp4-worker-3 /opt/iso/diskj.img  sds
virsh attach-disk ocp4-worker-3 /opt/iso/diskk.img  sdt
