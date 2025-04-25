#!/bin/bash -l
set -e
git config --global --add safe.directory *
Rscript -e "deploydocs::deploy_site()"
Rscript -e "try(deploydocs::update_sitemap())"
echo "Action complete!"
