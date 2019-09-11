import os

from pygluu.containerlib import get_manager


def main():
    manager = get_manager()

    if not os.path.isfile("/etc/certs/gluu_https.crt"):
        # pull SSL cert to a file
        manager.secret.to_file("ssl_cert", "/etc/certs/gluu_https.crt")

    if not os.path.isfile("/etc/certs/gluu_https.key"):
        # pull SSL key to a file
        manager.secret.to_file("ssl_key", "/etc/certs/gluu_https.key")


if __name__ == "__main__":
    main()
