#Make ocs-storagecluster-ceph-rbd the default storage class
oc patch storageclass ocs-storagecluster-ceph-rbd  -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
