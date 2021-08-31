#' Deploy docs
#'
#' Push pkgdown site to docs.ropensci.org and try to set commit status.
#'
#' @export
#' @param gha_result result of pkgdown site
#' @param buildlog url to build logs
deploy_and_update_status <- function(gha_result = Sys.getenv('GHA_RESULT'), buildlog = Sys.getenv('BUILDLOG')){
  if(grepl("suc", gha_result)){
    cat("Docs build was successful. Deploying to https://docs.ropensci.org")
    deploy_site('ropensci-docs', buildlog = buildlog)
  }
  #gh_app_set_commit_status
}

deploy_site <- function(deploy_org, buildlog, docsfile = 'docs-website/docs.zip'){
  # Extract docs zip
  print(list.files(recursive = T))
  docsfile <- normalizePath(docsfile, mustWork = TRUE)
  dir.create('deploy')
  setwd('deploy')
  utils::unzip(docsfile)

  # Get metadata
  info <- jsonlite::read_json('info.json')
  commit_url <- paste0(info$remote, "/commit/", substring(info$commit$commit,1,7))
  commit_message <- sprintf('Render from %s (%s...)\nBuild log: %s\n', commit_url,
                            substring(trimws(info$commit$message), 1, 25), buildlog)
  pkg <- info$pkg
  deploy_repo <- paste0(deploy_org, "/", pkg)
  deploy_remote <- paste0('https://github.com/', deploy_repo)

  # Create the repo
  gert::git_init()
  gert::git_add('.')
  commit_for_ropensci(commit_message, info$commit$author, info$commit$time)
  gert::git_remote_add(url = deploy_remote)
  gert::git_branch_create("gh-pages", checkout = TRUE)

  # Check if repo exists.
  # This should no longer be needed, we create repos now in sync_ropensci_docs
  tryCatch(gh::gh(paste0("/repos/", deploy_repo)), http_error_404 = function(e){
    cat(sprintf("Repo does not yet exist: %s\n", deploy_repo))
    create_new_docs_repo(pkg)
  })
  cat(sprintf("Pushing to %s\n", deploy_remote), file = stderr())
  gert::git_push('origin', force = TRUE, verbose = TRUE)
}

create_new_docs_repo <- function(name){
  message("Creating: ropensci-docs/", name)
  description <- paste0('auto-generated pkgdown website for: ', name)
  homepage <- paste0("https://docs.ropensci.org/", name)
  gh::gh('/orgs/ropensci-docs/repos', .method = 'POST',
         name = name, description = description, homepage = homepage,
         has_issues = FALSE, has_wiki = FALSE)
}

commit_for_ropensci <- function(message, author, time = NULL){
  author_name <- sub('^(.*)<(.*)>$', '\\1', author)
  author_email <- sub('^(.*)<(.*)>$', '\\2', author)
  author_sig <- gert::git_signature(name = author_name, email = author_email, time = time)
  commit_sig <- gert::git_signature(name = 'rOpenSci', email = 'info@ropensci.org', time = time)
  gert::git_commit(message = message, author = author_sig, committer = commit_sig)
}


#' Set Commit Status
#'
#' Sets the commit status on a commit from a GitHub App.
#' Requires the `GH_APP_KEY` environment variable.
#'
#' @param repo full repo name for example "ropensci/magick"
#' @param sha hash of the commit to update
#' @param url link to the build logs
#' @param pkg name of the R package
#' @param state string with result of rendering pkgdown
gh_app_set_commit_status <- function(repo, sha, url, pkg, state){
  if(is.na(Sys.getenv('GH_APP_KEY', NA)))
    stop("GH_APP_KEY missing")
  repo <- sub("https?://github.com/", "", repo)
  repo <- sub("\\.git$", "", repo)
  token <- ghapps::gh_app_token(app_id = '87942', repo)
  endpoint <- sprintf('/repos/%s/statuses/%s', repo, sha)
  context <- sprintf('ropensci/docs')
  description <- 'Render pkgdown documentation'
  if(state == 'success'){
    url <- sprintf('https://docs.ropensci.org/', pkg)
  }
  gh::gh(endpoint, .method = 'POST', .token = token, state = state,
         target_url = url, context = context, description = description)
}
