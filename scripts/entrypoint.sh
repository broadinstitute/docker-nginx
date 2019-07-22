#!/bin/sh
set -e

# ========
# FUNCTION
# ========

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

# ==========
# ENTRYPOINT
# ==========

cat << LICENSE_ACK

# ================================================================================================ #
# Gluu License Agreement: https://github.com/GluuFederation/enterprise-edition/blob/4.0.0/LICENSE. #
# The use of Gluu Server Enterprise Edition is subject to the Gluu Support License.                #
# ================================================================================================ #

LICENSE_ACK

if [ "$GLUU_CONFIG_ADAPTER" != "consul" ]; then
    echo "This container only support Consul as config backend."
    exit 1
fi

if [ "$GLUU_SECRET_ADAPTER" != "vault" ]; then
    echo "This container only support Vault as secret backend."
    exit 1
fi

deps="config,secret"

if [ -f /etc/redhat-release ]; then
    source scl_source enable python27 && gluu-wait --deps="$deps"
else
    gluu-wait --deps="$deps"
fi

if [ ! -f /deploy/touched ]; then
    if [ -f /touched ]; then
        mv /touched /deploy/touched
    else
        if [ -f /etc/redhat-release ]; then
            source scl_source enable python27 && python /app/scripts/entrypoint.py
        else
            python /app/scripts/entrypoint.py
        fi
    fi
    touch /deploy/touched
fi

exec consul-template \
    -log-level info \
    -template "/app/templates/gluu_https.conf.ctmpl:/etc/nginx/conf.d/default.conf" \
    -wait 5s \
    -exec "nginx" \
    -exec-reload-signal SIGHUP \
    -exec-kill-signal SIGQUIT \
    $(get_consul_opts)
