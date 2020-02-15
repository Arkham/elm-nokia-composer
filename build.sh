#! /bin/bash

set -euxo pipefail

watch elm make src/Main.elm --output app.js
