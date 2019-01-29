#!/usr/bin/env bash


# Check for nginx
which nginx || {
apt-get update -y
apt-get install nginx -y
}

var1=$(hostname)
# Create script check

cat << EOF > /usr/local/bin/check_wel.sh
#!/usr/bin/env bash

curl 127.0.0.1:80 | grep "Welcome to"
EOF

chmod +x /usr/local/bin/check_wel.sh

# Register nginx in consul
cat << EOF > /etc/.consul.d/web.json
{
    "service": {
        "name": "web",
        "tags": ["${var1}"],
        "port": 80
    },
    "checks": [
        {
            "id": "nginx_http_check",
            "name": "Check nginx1",
            "http": "http://127.0.0.1:80",
            "tls_skip_verify": false,
            "method": "GET",
            "interval": "10s",
            "timeout": "1s"
        },
        {
            "id": "nginx_tcp_check",
            "name": "TCP on port 80",
            "tcp": "127.0.0.1:80",
            "interval": "10s",
            "timeout": "1s"
        },
        {
            "id": "nginx_script_check",
            "name": "Welcome check",
            "args": ["/usr/local/bin/check_wel.sh", "-limit", "256MB"],
            "interval": "10s",
            "timeout": "1s"
        }
    ]
}
EOF


value=`curl -sL https://127.0.0.1:8501/v1/kv/${var1}/site?raw --cacert /etc/tls/consul-agent-ca.pem`
echo $value > /var/www/html/index.nginx-debian.html


systemctl restart nginx.service

sleep 1
consul reload -ca-file=/etc/tls/consul-agent-ca.pem -client-cert=/etc/tls/dc1-cli-consul-0.pem -client-key=/etc/tls/dc1-cli-consul-0-key.pem -http-addr="https://localhost:8501"