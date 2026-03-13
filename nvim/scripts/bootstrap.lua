#!/usr/bin/env -S nvim -l

require("my.env").init("bootstrap")
require("my.settings")
require("my.lazy.bootstrap")("verbose")
