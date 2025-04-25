#' Deploy docs
#'
#' Push pkgdown site from zip file to docs.ropensci.org
#'
#' @export
#' @param path directory containing the website to deploy
#' @param deploy_org github organization to host docs
#' @param buildlog url to build logs
deploy_site <- function(path = 'docs-website', deploy_org = 'ropensci-docs', buildlog = Sys.getenv('BUILDLOG')){
  setwd(path)

  info <- jsonlite::read_json('info.json')
  commit_url <- paste0(info$repo, "/commit/", substring(info$commit$commit,1,7))
  commit_message <- sprintf('Render from %s (%s...)\nBuild: %s\n', commit_url,
                            substring(gsub('@', '', trimws(info$commit$message)), 1, 25), buildlog)
  pkg <- info$pkg
  deploy_repo <- paste0(deploy_org, "/", pkg)
  deploy_remote <- paste0('https://github.com/', deploy_repo)

  # Create the repo
  gert::git_config_global_set('safe.directory', '*')
  gert::git_init()
  gert::git_add('.')
  commit_for_ropensci(commit_message, info$commit$author)
  gert::git_remote_add(url = deploy_remote)
  gert::git_branch_create("gh-pages", checkout = TRUE)

  # Check if repo exists.
  print(tryCatch(gh::gh(paste0("/repos/", deploy_repo)), http_error_404 = function(e){
    cat(sprintf("Repo does not yet exist: %s\n", deploy_repo))
    print(create_new_docs_repo(pkg))
    Sys.sleep(10)
  }))
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

commit_for_ropensci <- function(message, author){
  author_name <- sub('^(.*)<(.*)>$', '\\1', author)
  author_email <- sub('^(.*)<(.*)>$', '\\2', author)
  author_sig <- gert::git_signature(name = author_name, email = author_email)
  gert::git_commit(message = message, author = author_sig, committer = ropensci_sig())
}

ropensci_sig <- function(){
  #gert::git_signature(name = 'rOpenSci', email = 'info@ropensci.org')
  gert::git_signature(name = 'r-universe[bot]', email = '74155986+r-universe[bot]@users.noreply.github.com')
}
