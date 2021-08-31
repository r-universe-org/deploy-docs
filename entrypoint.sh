#!/bin/bash -l
set -e
Rscript -e "deploydocs::deploy_and_update_status()"
echo "Action complete!"
