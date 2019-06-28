#!/usr/bin/env python

from __future__ import print_function

import os
import sys

target = os.path.abspath(sys.argv[1])
link_name = sys.argv[2]

if not os.path.exists(link_name):
    sys.exit(1)

if os.path.abspath(os.readlink(link_name)) == target:
    sys.exit(0)

sys.exit(1)
