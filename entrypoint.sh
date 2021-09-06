#!/bin/bash -l
set -e
Rscript -e "deploydocs::deploy_site()"
Rscript -e "try(deploydocs::update_sitemap())"
echo "Action complete!"
