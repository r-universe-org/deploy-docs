#' Generate and push docs sitemap
#'
#' @export
update_sitemap <- function(){
  cat("Updating index.html and sitemap.xml at https://docs.ropensci.org\n")
  tmpdir <- tempfile()
  repo <- gert::git_clone('https://github.com/ropensci-docs/ropensci-docs.github.io', tmpdir)
  generate_sitemap(tmpdir)
  gert::git_add(c('index.html', 'sitemap.xml'), repo = repo)
  if(any(gert::git_status(repo = repo)$staged)){
    gert::git_commit(sprintf("Update sitemap (%s)", Sys.Date()), repo = repo)
    gert::git_push(repo = repo)
  } else {
    message("No changes in sitemap")
  }
}

generate_sitemap <- function(path){
  sites <- get_docs_repos(active_only = TRUE)

  skiplist <- 'ropensci-docs.github.io'
  sites <- Filter(function(x){!(x %in% skiplist)}, sites)

  # Generate sitemap.xml
  body <- sprintf("  <url>\n    <loc>https://docs.ropensci.org/%s/</loc>\n  </url>", sites)
  sitemap <- paste(c('<?xml version="1.0" encoding="UTF-8"?>',
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
    body, '</urlset>'), collapse = '\n')
  writeLines(sitemap, file.path(path, 'sitemap.xml'))

  # Generate index.html
  template <- system.file('templates/index.html', package = 'deploydocs')
  input <- rawToChar(readBin(template, raw(), file.info(template)$size))
  li <- sprintf('  <li><a href="https://docs.ropensci.org/%s/">%s</a></li>', sites, sites)
  output <- sub('INSERT_REPO_LIST', paste(li, collapse = '\n'), input)
  writeLines(output, file.path(path, 'index.html'))
}

get_docs_repos <- function(active_only = FALSE){
  out <- list_ropensci_docs_repos()
  if(isTRUE(active_only))
    out <- Filter(function(x){isTRUE(x$active)}, out)
  unlist(lapply(out, `[[`, 'name'))
}

list_ropensci_docs_repos <- function(){
  repos <- gh::gh('/users/ropensci-docs/repos?per_page=100', .limit = 1e6)
  lapply(repos, function(x){
    x$active = abs(parse_time(x$pushed_at) - parse_time(x$created_at)) > 1
    return(x)
  })
}

parse_time <- function(str){
  strptime(str, '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')
}
