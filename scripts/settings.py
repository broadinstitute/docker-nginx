LOGGING_CONFIG = {
    "version": 1,
    "formatters": {
        "default": {
            "format": "%(levelname)s - %(name)s - %(asctime)s - %(message)s",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "default",
        },
    },
    "loggers": {
        "pygluu.containerlib": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": True,
        },
        "wait": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
    },
    # "root": {
    #     "level": "INFO",
    #     "handlers": ["console"],
    # },
}
