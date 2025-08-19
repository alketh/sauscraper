# we will only scrape urls here. They have all the info we need.
library(rvest)
library(tibble)
library(DBI)
library(RPostgres)

source("utils.R")

url <- Sys.getenv("RVAR_URL")

content <- read_html(url)

links <- html_elements(content, "a")
links <- html_attr(links, "href")
is_link <- grepl("icalrepeat.detail", links)
links <- links[is_link]

can_links <- paste0(strsplit(Sys.getenv("RVAR_URL"), "/de/")[[1]][1], links)

out <- tibble(url = can_links, created_at = Sys.time())

# Add a testevent
# out <- create_testevent_simple()

con <- con_sau()

dbExecute(con, "DROP TABLE IF EXISTS temp_events")
dbWriteTable(con, name = "temp_events", value = out)

# Recreate from scratch
# dbExecute(con, "DROP TABLE IF EXISTS events_simple")
# dbWriteTable(con, name = "events_simple", value = out)

# Check for new entries!
urls <- dbGetQuery(con, "select distinct url from events_simple")

new <- out$url[!out$url %in% urls$url]

check <- length(new) > 0

# Add new events and report
if (check) {
  add <- out[out$url %in% new, ]
  
  send_signal("\"Neues Sau Event entdeckt\"")
  
  # for (i in seq_len(nrow(add))) {
  #   chr_url <- add$url[i]
  #   send_signal(chr_url)
  # }
  
  send_signal(paste0("'",paste(add$url, collapse = "\n"), "'"))
  
  send_signal("\"Ende der Übertragung!\"")
  
  
  nn <- dbAppendTable(con, name = "events_simple", value = add)
}

# display all events
dd <- dbGetQuery(con, "select * from events_simple")
kable(dd)

dbDisconnect(con)
