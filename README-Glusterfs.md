= Initial Glusterfs backend storage providing =
* Gluster backend storage nodes (**)
* Cinder and/or Glance (on controller) as glusterfs clients - Swift is there but not used yet
(**)I use separate nodes for storage but could be on a controller or a network node as well to use disk space

Dependencies
* glusterfs repo must be added. Currently tested using glusterfs epel 3.4.1
* Requires following git repo to be added to puppet/foreman: https://github.com/redhat-openstack/puppet-openstack-storage (Misnomer)

Issues/To do

* glusterfs client (Glusterfs-fuse) added on compute nodes manifest but not tested yet (manually installed)
* SELINUX must be permissive:
** On compute nodes: cinder/glusterfs mounts not allowed by libvirt  
* FW  
** BZ#906314  
** Storage nodes: A port must be opened for each brick (times the number of volumes) - Tricky [WIP]


