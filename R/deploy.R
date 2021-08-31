#' Deploy docs
#'
#' Pushes artifact to docs.ropensci.org and try to update commit status.
#'
deploy_and_update_status <- function(){
  gha_url <- Sys.getenv('GHA_URL')
  gha_status <- Sys.getenv('GHA_STATUS')
  docspwd <- Sys.getenv('DOCSPWD')
  appkey <- Sys.getenv('GH_APP_KEY')
}
