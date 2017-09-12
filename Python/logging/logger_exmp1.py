#!/bin/env python

import logging
import logging.config

logging.config.fileConfig("logger.conf")
logger=logging.getLogger("example01")

logger.debug("This IS DEBUG log")
logger.info("This IS INFO log")
logger.warning("This IS WARNING log")
