## PostgreSQL High-Availability Cluster by Patroni using ETCD cluster. CM: Automating deployment with Ansible.

- Patroni is a cluster manager used to customize and automate deployment and maintenance of PostgreSQL HA (High Availability) clusters. It uses distributed configuration stores like etcd, Consul, ZooKeeper or Kubernetes for maximum accessibility.

- etcd is a distributed reliable key-value store for the most critical data of a distributed system. etcd is written in Go and uses the Raft consensus algorithm to manage a highly-available replicated log. It is used by Patroni to store information about the status of the cluster and PostgreSQL configuration parameters.

- HAProxy is a free, very fast and reliable solution offering high availability, load balancing, and proxying for TCP and HTTP-based applications.

### Architecture overview:

Etcd three node cluster (DCS:Distributed Configuration Store):

<img src="pictures/etcd_three_node.png" width="600">

When all the nodes are up and running:

<img src="pictures/patroni_streaming_replication.png" width="600">

HAProxy (OPTIONAL):

<img src="pictures/haproxy_loadblance_postgres.png" width="600">

### Install needed software hcloud-cli/terraform/ansible on control node (laptop in this example)

```
Linux:

$ TER_VER=`curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1'`
$ wget https://releases.hashicorp.com/terraform/${TER_VER}/terraform_${TER_VER}_linux_amd64.zip && unzip terraform_${TER_VER}_linux_amd64.zip && chmod +x terraform && sudo mv terraform /usr/local/bin/$ sudo apt update && apt install python3-pip sshpass git -y$ 
$ sudo pip3 install ansible
$ wget hcloud-linux-amd64.tar.gz && unzip hcloud-linux-amd64.tar.gz && chmod +x hcloud && sudo mv hcloud /usr/local/bin

Mac:

% brew tap hashicorp/tap
% brew install hashicorp/tap/terraform
% brew install ansible
% brew install hcloud
```

### Provision 3 Hetzner Cloud VMs with terraform for ansible testing:

```
$ git clone https://github.com/adavarski/postgres-ha; cd postgres-ha
$ cd ./infrastructure

# Setup hcloud_token

$ cat terraform.tfvars

multi_master = true
master_node_count  = 1
slave_node_count  = 2 
hcloud_token = "XXXXXXXXXXXXXXXXX" 

$ terraform init
$ terraform plan
$ terraform apply

% export HCLOUD_TOKEN="XXXXXXXXXXXXXXX"

% hcloud server list
ID         NAME        STATUS    IPV4             IPV6                      DATACENTER
16186761   master001   running   95.217.214.188   2a01:4f9:c011:5b28::/64   hel1-dc2
16186762   slave001    running   95.217.218.112   2a01:4f9:c011:5c48::/64   hel1-dc2
16186763   slave002    running   95.217.220.46    2a01:4f9:c011:5bd4::/64   hel1-dc2
```

### Provisioning PostgreSQL HA Cluster:

Note: The cluster is configured with a single primary and two asynchronous streaming replica in this example:

```

$ cd ../postgresql_cluster
### edit ansible inventory file and run playbook

$ ansible-playbook -i ./inventory deploy_pgcluster.yml
...
PLAY RECAP *********************************************************************************************************************
95.217.214.188             : ok=105  changed=61   unreachable=0    failed=0    skipped=329  rescued=0    ignored=0   
95.217.218.112             : ok=95   changed=60   unreachable=0    failed=0    skipped=316  rescued=0    ignored=0   
95.217.220.46              : ok=95   changed=60   unreachable=0    failed=0    skipped=316  rescued=0    ignored=0   
localhost                  : ok=0    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   

### ssh to master and check cluster:

% ssh root@95.217.214.188

root@master001:~# patronictl topology
+------------+----------------+---------+---------+----+-----------+
| Member     | Host           | Role    | State   | TL | Lag in MB |
+ Cluster: postgres-cluster (7033339216356814121) +----+-----------+
| master001  | 95.217.214.188 | Leader  | running |  1 |           |
| + slave001 | 95.217.218.112 | Replica | running |  1 |         0 |
| + slave002 | 95.217.220.46  | Replica | running |  1 |         0 |
+------------+----------------+---------+---------+----+-----------+


### Note: postgres user password: postgres-pass

root@master001:~# psql -h localhost -U postgres
Password for user postgres: 
psql (13.5 (Ubuntu 13.5-2.pgdg20.04+1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)

````
### HAProxy (OPTIONAL: PostgreSQL High-Availability with HAProxy Load Balancing. Note: We can use Hetzner Load Balancer also)

We need to have HAProxy to listen for connections on the PostgreSQL standard port 5432. Then HAProxy should check the patroni api to determine which node is the primary.

Example HAProxy configuration:

```
global
	maxconn 100

defaults
	log global
	mode tcp
	retries 2
	timeout client 30m
	timeout connect 4s
	timeout server 30m
	timeout check 5s

listen stats
	mode http
	bind *:7000
	stats enable
	stats uri /

listen region_one
	bind *:5432
	option httpchk
	http-check expect status 200
	default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    	server patroni01 95.217.214.188:6432 maxconn 80 check port 8008
    	server patroni02 95.217.218.112:6432 maxconn 80 check port 8008
    	server patroni03 95.217.220.46:6432 maxconn 80 check port 8008
```


Other examples with Patroni & Consul/Zookeeper (Note: OLD)

- https://github.com/adavarski/vagrant-ansible-postgresql-ha-patroni-consul (3-node cluster of PostgreSQL, managed by Patroni using Consul cluster).

- https://github.com/adavarski/vagrant-postgresql-ha-patroni-zookeeper (3-node cluster of PostgreSQL, managed by Patroni using Zookeeper cluster).
