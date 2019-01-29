#!/usr/bin/env bash

#nameserver 127.0.0.53
#search consul


which unzip curl socat jq route dig vim || {
apt-get update -y
apt-get install unzip socat jq dnsutils net-tools vim curl -y 
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

if [[ "${var2}" =~ "consul-server" ]]; then
    mkdir -p /vagrant/conf/${var2}/cserver/.consul.d/
    killall consul
    SERVER_COUNT=${SERVER_COUNT}
    echo $SERVER_COUNT
    consul agent -server -ui -config-dir=/vagrant/conf/${var2}/cserver/.consul.d/ -bind ${IP} -client 0.0.0.0 -data-dir=/tmp/consul -log-level=${LOG_LEVEL} -enable-script-checks -bootstrap-expect=$SERVER_COUNT -node=$var2 -retry-join=10.10.56.11 -retry-join=10.10.56.12 > /vagrant/logs/$var2.log &

else
    if [[ "${var2}" =~ "client" ]]; then
        mkdir -p /vagrant/conf/${var2}/cclient/.consul.d/
        killall consul
        consul agent -ui -config-dir=/vagrant/conf/${var2}/cclient/.consul.d/ -bind ${IP} -client 0.0.0.0 -data-dir=/tmp/consul -log-level=${LOG_LEVEL} -enable-script-checks -node=$var2 -retry-join=10.10.56.11 -retry-join=10.10.56.12 > /vagrant/logs/$var2.log &
    fi
fi


sleep 5
consul members -ca-file=/vagrant/tls/consul-agent-ca.pem -client-cert=/vagrant/tls/dc1-cli-consul-0.pem -client-key=/vagrant/tls/dc1-cli-consul-0-key.pem -http-addr="https://localhost:8501"