import logging
import logging.config
import os
import sys

from pygluu.containerlib import get_manager
from pygluu.containerlib import wait_for

from settings import LOGGING_CONFIG

logging.config.dictConfig(LOGGING_CONFIG)
logger = logging.getLogger("wait")


def main():
    config_adapter = os.environ.get("GLUU_CONFIG_ADAPTER", "consul")
    if config_adapter != "consul":
        logger.error("This container only supports Consul as config backend")
        sys.exit(1)

    secret_adapter = os.environ.get("GLUU_SECRET_ADAPTER", "vault")
    if secret_adapter != "vault":
        logger.error("This container only supports Vault as secret backend")
        sys.exit(1)

    manager = get_manager()
    deps = ["config", "secret"]
    wait_for(manager, deps)


if __name__ == "__main__":
    main()
