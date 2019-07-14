from pygluu.containerlib import get_manager


def main(manager):
    # pull SSL cert to a file
    manager.secret.to_file("ssl_cert", "/etc/certs/gluu_https.crt")
    # pull SSL key to a file
    manager.secret.to_file("ssl_key", "/etc/certs/gluu_https.key")


if __name__ == "__main__":
    manager = get_manager()
    main(manager)
