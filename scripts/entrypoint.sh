#!/bin/sh
set -e

cat << LICENSE_ACK

# ========================================================================================= #
# Gluu License Agreement: https://github.com/GluuFederation/gluu-docker/blob/3.1.6/LICENSE. #
# The use of Gluu Server Docker Edition is subject to the Gluu Support License.             #
# ========================================================================================= #

LICENSE_ACK

get_consul_opts() {
    local consul_scheme=0

    local consul_opts="-consul-addr $GLUU_CONFIG_CONSUL_HOST:$GLUU_CONFIG_CONSUL_PORT"

    if [ $GLUU_CONFIG_CONSUL_SCHEME = "https" ]; then
        consul_opts="${consul_opts} -consul-ssl"

        if [ -f $GLUU_CONFIG_CONSUL_CACERT_FILE ]; then
            consul_opts="${consul_opts} -consul-ssl-ca-cert $GLUU_CONFIG_CONSUL_CACERT_FILE"
        fi

        if [ -f $GLUU_CONFIG_CONSUL_CERT_FILE ]; then
            consul_opts="${consul_opts} -consul-ssl-cert $GLUU_CONFIG_CONSUL_CERT_FILE"
        fi

        if [ -f $GLUU_CONFIG_CONSUL_KEY_FILE ]; then
            consul_opts="${consul_opts} -consul-ssl-key $GLUU_CONFIG_CONSUL_KEY_FILE"
        fi

        if [ $GLUU_CONFIG_CONSUL_VERIFY = "true" ]; then
            consul_opts="${consul_opts} -consul-ssl-verify"
        fi
    fi

    if [ -f $GLUU_CONFIG_CONSUL_TOKEN_FILE ]; then
        consul_opts="${consul_opts} -consul-token $(cat $GLUU_CONFIG_CONSUL_TOKEN_FILE)"
    fi
    echo $consul_opts
}

if [ "$GLUU_CONFIG_ADAPTER" != "consul" ]; then
    echo "This container only support Consul as config backend."
    exit 1
fi

if [ "$GLUU_SECRET_ADAPTER" != "vault" ]; then
    echo "This container only support Vault as secret backend."
    exit 1
fi

python /opt/scripts/wait_for.py --deps="config,secret"

if [ ! -f /deploy/touched ]; then
    if [ -f /touched ]; then
        mv /touched /deploy/touched
    else
        python /opt/scripts/entrypoint.py
        touch /deploy/touched
    fi
fi

exec consul-template \
    -log-level info \
    -template "/opt/templates/gluu_https.conf.ctmpl:/etc/nginx/conf.d/default.conf" \
    -wait 5s \
    -exec "nginx" \
    -exec-reload-signal SIGHUP \
    -exec-kill-signal SIGQUIT \
    $(get_consul_opts)
