TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD ceph status 
oc rsh -n openshift-storage $TOOLS_POD osd tree 
oc rsh -n openshift-storage $TOOLS_POD ceph health 
