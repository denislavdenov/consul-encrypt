#!/usr/bin/env bash

set -x
########################
#    Using REST API    #
########################

# Adding key/values
curl \
    --request PUT \
    --cacert /etc/tls/consul-agent-ca.pem \
    --data "nameNAME"  \
    https://127.0.0.1:8501/v1/kv/website-name

curl \
    --request PUT \
    --cacert /etc/tls/consul-agent-ca.pem \
    --data "@/vagrant/denislav.json"  \
    https://127.0.0.1:8501/v1/kv/denislav

curl \
    --request PUT \
    --cacert /etc/tls/consul-agent-ca.pem \
    --data '
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to client-nginx1!</title>
    <style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
    </style>
    </head>
    <body>
    <h1>Welcome to client-nginx1!</h1>
    <p><em>Thank you for using client-nginx1.</em></p>
    </body>
    </html>'  \
    https://127.0.0.1:8501/v1/kv/client-nginx1/site

curl \
    --request PUT \
    --cacert /etc/tls/consul-agent-ca.pem \
    --data '
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to client-nginx2!</title>
    <style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
    </style>
    </head>
    <body>
    <h1>Welcome to client-nginx2!</h1>
    <p><em>Thank you for using client-nginx2.</em></p>
    </body>
    </html>'  \
    https://127.0.0.1:8501/v1/kv/client-nginx2/site



# Getting values from keys

value=`curl -sL https://127.0.0.1:8501/v1/kv/website-name | jq '.[].Value' | tr -d '"' | base64 --decode --cacert /etc/tls/consul-agent-ca.pem`
echo $value

value=`curl -sL https://127.0.0.1:8501/v1/kv/denislav | jq '.[].Value' | tr -d '"' | base64 --decode --cacert /etc/tls/consul-agent-ca.pem`
echo $value
value=`curl -sL https://127.0.0.1:8501/v1/kv/client-nginx1/site?raw --cacert /vagrant/tls/consul-agent-ca.pem`
echo $value
curl -sL https://127.0.0.1:8501/v1/kv/denislav?raw --cacert /etc/tls/consul-agent-ca.pem
# Deleting key/values
curl \
    --request DELETE \
    --cacert /etc/tls/consul-agent-ca.pem \
    https://127.0.0.1:8501/v1/kv/website-name 

set +x