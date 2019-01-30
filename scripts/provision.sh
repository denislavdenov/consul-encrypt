#!/usr/bin/env bash

#nameserver 127.0.0.53
#search consul

set -x

which unzip curl socat jq route dig vim sshpass || {
apt-get update -y
apt-get install unzip socat jq dnsutils net-tools vim curl sshpass -y 
}

# Install consul\
CONSUL_VER=${CONSUL_VER}
which consul || {
echo "Determining Consul version to install ..."

CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
if [ -z "$CURRENT_VER" ]; then
    CURRENT_VER=$(curl -s "${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')
fi


if  ! [ "$CONSUL_VER" == "$CURRENT_VER" ]; then
    echo "THERE IS NEWER VERSION OF CONSUL: ${CURRENT_VER}"
    echo "Install is going to proceed with the older version: ${CONSUL_VER}"
fi

if [ -f "/vagrant/pkg/consul_${CONSUL_VER}_linux_amd64.zip" ]; then
		echo "Found Consul in /vagrant/pkg"
else
    echo "Fetching Consul version ${CONSUL_VER} ..."
    mkdir -p /vagrant/pkg/
    curl -s https://releases.hashicorp.com/consul/${CONSUL_VER}/consul_${CONSUL_VER}_linux_amd64.zip -o /vagrant/pkg/consul_${CONSUL_VER}_linux_amd64.zip
    if [ $? -ne 0 ]; then
        echo "Download failed! Exiting."
        exit 1
    fi
fi

echo "Installing Consul version ${CONSUL_VER} ..."
pushd /tmp
unzip /vagrant/pkg/consul_${CONSUL_VER}_linux_amd64.zip 
sudo chmod +x consul
sudo mv consul /usr/local/bin/consul

}


# Starting consul
killall consul

LOG_LEVEL=${LOG_LEVEL}
if [ -z "${LOG_LEVEL}" ]; then
    LOG_LEVEL="info"
fi

var1=$(hostname -I | cut -f2 -d' ')
var2=$(hostname)
IFACE=`route -n | awk '$1 ~ "10.10" {print $8}'`
CIDR=`ip addr show ${IFACE} | awk '$2 ~ "10.10" {print $2}'`
IP=${CIDR%%/24}
mkdir -p /vagrant/logs
mkdir -p /etc/.consul.d
mkdir -p /etc/tls

cat << EOF > /etc/.consul.d/tls.json

{
  "verify_incoming_rpc": true,
  "verify_incoming_https": false,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ca_file": "/etc/tls/consul-agent-ca.pem",
  "cert_file": "/etc/tls/xxx",
  "key_file": "/etc/tls/yyy",
  "ports": {
    "http": -1,
    "https": 8501
  },
  
  "ui": true,
  "client_addr": "0.0.0.0",
  "disable_remote_exec": true
  
}

EOF



if [[ "${var2}" == "consul-server1" ]]; then
    encr=`consul keygen`
    cat << EOF > /etc/.consul.d/encrypt.json

    {
        "encrypt": "${encr}"
    }
EOF

    pushd /etc/tls
    if ! [ -e "consul-agent-ca.pem" ] && ! [ -e "consul-agent-ca-key.pem" ]; then
    consul tls ca create
    fi
    
else
    if ! [ -e "consul-agent-ca.pem" ] && ! [ -e "consul-agent-ca-key.pem" ]; then
        sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no vagrant@10.10.56.11:"/etc/tls/consul-agent-ca*" /etc/tls/ 
    fi
    popd
fi

pushd /etc/tls
if ! [ -f "dc1-cli-consul-0.pem" ] && ! [ -f "dc1-cli-consul-0-key.pem" ]; then
    consul tls cert create -cli
fi
popd



if [[ "${var2}" =~ "consul-server" ]]; then
    pushd /etc/tls/
    if ! [ -f "dc1-server-consul-0.pem" ] && ! [ -f "dc1-server-consul-0-key.pem" ]; then
        consul tls cert create -server
    fi 
    popd   
    sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no vagrant@10.10.56.11:"/etc/.consul.d/encrypt.json" /etc/.consul.d/
    sed -i -e 's/xxx/dc1-server-consul-0.pem/g' /etc/.consul.d/tls.json
    sed -i -e 's/yyy/dc1-server-consul-0-key.pem/g' /etc/.consul.d/tls.json
    
    killall consul
    SERVER_COUNT=${SERVER_COUNT}
    echo $SERVER_COUNT
    consul agent -server -ui -config-dir=/etc/.consul.d/ -bind ${IP} -client 0.0.0.0 -data-dir=/tmp/consul -log-level=${LOG_LEVEL} -enable-script-checks -bootstrap-expect=$SERVER_COUNT -node=$var2 -retry-join=10.10.56.11 -retry-join=10.10.56.12 > /vagrant/logs/$var2.log &

else
    if [[ "${var2}" =~ "client" ]]; then
        pushd /etc/tls/
        if ! [ -f "dc1-client-consul-0.pem" ] && ! [ -f "dc1-client-consul-0-key.pem" ]; then
            consul tls cert create -client
        fi  
        popd  
        sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no vagrant@10.10.56.11:"/etc/.consul.d/encrypt.json" /etc/.consul.d/
        sed -i -e 's/xxx/dc1-client-consul-0.pem/g' /etc/.consul.d/tls.json
        sed -i -e 's/yyy/dc1-client-consul-0-key.pem/g' /etc/.consul.d/tls.json
        killall consul
        consul agent -ui -config-dir=/etc/.consul.d -bind ${IP} -client 0.0.0.0 -data-dir=/tmp/consul -log-level=${LOG_LEVEL} -enable-script-checks -node=$var2 -retry-join=10.10.56.11 -retry-join=10.10.56.12 > /vagrant/logs/$var2.log &
    fi
fi


sleep 5
consul members -ca-file=/etc/tls/consul-agent-ca.pem -client-cert=/etc/tls/dc1-cli-consul-0.pem -client-key=/etc/tls/dc1-cli-consul-0-key.pem -http-addr="https://localhost:8501"

set +x