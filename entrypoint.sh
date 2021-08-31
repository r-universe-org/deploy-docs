#!/bin/bash -l
set -e
Rscript -e "deploydocs::deploy_site()"
echo "Action complete!"
