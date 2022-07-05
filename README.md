# Action: deploy-docs

This action is currently only enabled for the [ropensci universe](https://ropensci.r-universe.dev) as part of the standard [build workflow](https://github.com/r-universe-org/workflows/blob/master/build.yml).

It takes the pkgdown site that was built in the previous [build-docs](https://github.com/r-universe-org/build-docs) action and deploys to `https://github.com/ropensci-docs` which is an alias for https://docs.ropensci.org.
