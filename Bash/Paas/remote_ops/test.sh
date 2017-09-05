#!/bin/bash

ATOMOP_DIR=atom_ops/
CONFIG_FILE=config/host_ip.list
TMPDIR=tmp/

$ATOMOP_DIR/exe_remote.exp 10.10.202.18 lijing ucpaas.com "wc -l /opt/paas/smsp5.0/smsp_c2s/logs/smsp_c2s.log"
