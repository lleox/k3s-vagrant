#!/bin/bash
set -eux

k3s_version="$1"; shift
k3s_cluster_secret="$1"; shift
k3s_url="$1"; shift
ip_address="$1"; shift

# configure the motd.
# NB this was generated at http://patorjk.com/software/taag/#p=display&f=Big&t=k3s%0Aagent.
#    it could also be generated with figlet.org.
cat >/etc/motd <<'EOF'

  _    ____
 | |  |___ \
 | | __ __) |___
 | |/ /|__ </ __|        _
 |   < ___) \__ \       | |
 |_|\_\____/|___/_ _ __ | |_
  / _` |/ _` |/ _ \ '_ \| __|
 | (_| | (_| |  __/ | | | |_
  \__,_|\__, |\___|_| |_|\__|
         __/ |
        |___/

EOF

# install k3s.
curl -sfL https://raw.githubusercontent.com/rancher/k3s/$k3s_version/install.sh \
    | \
        INSTALL_K3S_VERSION="$k3s_version" \
        K3S_CLUSTER_SECRET="$k3s_cluster_secret" \
        K3S_URL="$k3s_url" \
        sh -s -- \
            agent \
            --node-ip "$ip_address" \
            --flannel-iface 'eth1'

# see the systemd unit.
systemctl cat k3s-agent

# NB do not try to use kubectl on a agent node, as kubectl does not work on a
#    agent node without a proper kubectl configuration (which you could copy
#    from the server).

# wait for the svclb-traefik pod to be Running.
# e.g. eca1ea99515cd       About an hour ago   Ready               svclb-traefik-kz562   kube-system         0
$SHELL -c 'while [ -z "$(crictl pods --label app=svclb-traefik | grep -E "\s+Ready\s+")" ]; do sleep 3; done'

# list runnnig pods.
crictl pods

# list running containers.
crictl ps
k3s ctr containers ls

# show listening ports.
ss -n --tcp --listening --processes

# show network routes.
ip route

# show memory info.
free

# show versions.
crictl version
k3s ctr version
