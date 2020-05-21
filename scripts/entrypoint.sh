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

python3 /app/scripts/wait.py
if [ ! -f /deploy/touched ]; then
    python3 /app/scripts/entrypoint.py
    touch /deploy/touched
fi

exec consul-template \
    -log-level info \
    -template "/app/templates/gluu_https.conf.ctmpl:/etc/nginx/conf.d/default.conf" \
    -wait 10s \
    -exec "nginx" \
    -exec-reload-signal SIGHUP \
    -exec-kill-signal SIGQUIT \
    $(get_consul_opts)
