FROM nginx:stable-alpine

LABEL maintainer="Gluu Inc. <support@gluu.org>"

# ===============
# Alpine packages
# ===============

RUN apk update && apk add --no-cache \
    openssl \
    py-pip \
    shadow

# =====
# nginx
# =====

RUN mkdir -p /etc/certs
RUN openssl dhparam -out /etc/certs/dhparams.pem 2048
# COPY templates/nginx.conf /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Ports for nginx
EXPOSE 80
EXPOSE 443

# ======
# Python
# ======

COPY requirements.txt /tmp/
RUN pip install -U pip \
    && pip install -r /tmp/requirements.txt --no-cache-dir

# ===============
# consul-template
# ===============

ENV CONSUL_TEMPLATE_VERSION 0.19.4

RUN wget -q https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.tgz -O /tmp/consul-template.tgz \
    && tar xf /tmp/consul-template.tgz -C /usr/bin/ \
    && chmod +x /usr/bin/consul-template \
    && rm /tmp/consul-template.tgz

# ====
# Tini
# ====

ENV TINI_VERSION v0.18.0
RUN wget -q https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static -O /usr/bin/tini \
    && chmod +x /usr/bin/tini

# =======
# License
# =======

RUN mkdir -p /licenses
COPY LICENSE /licenses/

# ==========
# Config ENV
# ==========

ENV GLUU_CONFIG_ADAPTER consul
ENV GLUU_CONFIG_CONSUL_HOST localhost
ENV GLUU_CONFIG_CONSUL_PORT 8500
ENV GLUU_CONFIG_CONSUL_CONSISTENCY stale
ENV GLUU_CONFIG_CONSUL_SCHEME http
ENV GLUU_CONFIG_CONSUL_VERIFY false
ENV GLUU_CONFIG_CONSUL_CACERT_FILE /etc/certs/consul_ca.crt
ENV GLUU_CONFIG_CONSUL_CERT_FILE /etc/certs/consul_client.crt
ENV GLUU_CONFIG_CONSUL_KEY_FILE /etc/certs/consul_client.key
ENV GLUU_CONFIG_CONSUL_TOKEN_FILE /etc/certs/consul_token
ENV GLUU_CONFIG_KUBERNETES_NAMESPACE default
ENV GLUU_CONFIG_KUBERNETES_CONFIGMAP gluu
ENV GLUU_CONFIG_KUBERNETES_USE_KUBE_CONFIG false

# ==========
# Secret ENV
# ==========

ENV GLUU_SECRET_ADAPTER vault
ENV GLUU_SECRET_VAULT_SCHEME http
ENV GLUU_SECRET_VAULT_HOST localhost
ENV GLUU_SECRET_VAULT_PORT 8200
ENV GLUU_SECRET_VAULT_VERIFY false
ENV GLUU_SECRET_VAULT_ROLE_ID_FILE /etc/certs/vault_role_id
ENV GLUU_SECRET_VAULT_SECRET_ID_FILE /etc/certs/vault_secret_id
ENV GLUU_SECRET_VAULT_CERT_FILE /etc/certs/vault_client.crt
ENV GLUU_SECRET_VAULT_KEY_FILE /etc/certs/vault_client.key
ENV GLUU_SECRET_VAULT_CACERT_FILE /etc/certs/vault_ca.crt
ENV GLUU_SECRET_KUBERNETES_NAMESPACE default
ENV GLUU_SECRET_KUBERNETES_SECRET gluu
ENV GLUU_SECRET_KUBERNETES_USE_KUBE_CONFIG false

# ===========
# Generic ENV
# ===========

ENV GLUU_WAIT_MAX_TIME 300
ENV GLUU_WAIT_SLEEP_DURATION 5

# ==========
# misc stuff
# ==========

LABEL vendor="Gluu Federation"

RUN mkdir -p /app/scripts /app/templates /deploy
COPY templates/gluu_https.conf.ctmpl /app/templates/
COPY scripts /app/scripts/

# # create non-root user
# RUN usermod -u 1000 nginx \
#     && usermod -a -G root nginx

# # adjust ownership
# RUN chown -R 1000:1000 /deploy \
#     && chgrp -R 0 /deploy && chmod -R g=u /deploy \
#     && chgrp -R 0 /etc/certs && chmod -R g=u /etc/certs \
#     && chgrp -R 0 /etc/nginx/conf.d && chmod -R g=u /etc/nginx/conf.d \
#     && chmod g=u /var/run/nginx.pid
#     # && chgrp 0 /var/run/nginx.pid && chmod g=u /var/run/nginx.pid

# USER 1000

ENTRYPOINT ["tini", "-g", "--"]
CMD ["sh", "/app/scripts/entrypoint.sh"]
