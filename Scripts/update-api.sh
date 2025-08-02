#!/bin/bash
# Convenience script to update the API client
# This just calls the actual script in the PeatedAPI package

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/../PeatedAPI" && ./update-api.sh