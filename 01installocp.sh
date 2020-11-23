systemctl restart dnsmasq

systemctl restart libvirtd

rm -rf /var/lib/libvirt/dnsmasq/virbr0.*

export CLUSTER_NAME=ocp4
export N_MAST=3
export N_WORK=3
export MAS_CPU=4
export MAS_MEM=16000
export WOR_CPU=6
export WOR_MEM=16000
export BTS_CPU=4
export BTS_MEM=16000
export LB_CPU=1
export LB_MEM=1024
./NEW_ocp4_setup_upi_kvm.sh --ocp-version 4.6.stable
