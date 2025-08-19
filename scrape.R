library(rvest)
library(stringr)
library(tibble)
library(purrr)
library(lubridate)
library(DBI)
library(RPostgres)
library(openssl)
library(knitr)

source("utils.R")

url <- Sys.getenv("RVAR_URL")

content <- read_html(url)

divs <- html_elements(content, "li") 

txt <- html_text(divs)

is_row <- html_attr(divs, "class") == "ev_td_li"
is_row[is.na(is_row)] <- FALSE

res <- txt[is_row]

raw <- str_split_fixed(res, pattern = "\n", n = 3)

time <- str_split_fixed(raw[, 2], pattern = " - ", n = 2)

# lets keep it simple
out <- tibble(time = str_trim(raw[, 2]), event = str_trim(raw[, 3]))
out

# lets make it fancy
# x <- time[1, 1]

out$from_weekday <- map_chr(time[, 1], parse_weekday)
out$from_date <- map_chr(time[, 1], parse_date)
out$from_time <- map_chr(time[, 1], parse_time)

out$to_weekday <- map_chr(time[, 2], parse_weekday)
out$to_date <- map_chr(time[, 2], parse_date)
out$to_time <- map_chr(time[, 2], parse_time)

missing_date <- is.na(out$to_date)

out$to_weekday[missing_date] <- out$from_weekday[missing_date]
out$to_date[missing_date] <- out$from_date[missing_date]

out$from_date <- as.Date(out$from_date, format = "%d.%m.%y")
out$to_date <- as.Date(out$to_date, format = "%d.%m.%y")

out$time <- NULL

# Add meta data
out$id <- md5(apply(out, 1, paste, collapse = "|"))
out$created_at <- Sys.time()

# Add links
links <- html_elements(content, "a")
links <- html_attr(links, "href")
is_link <- grepl("icalrepeat.detail", links)
links <- links[is_link]

can_links <- paste0(strsplit(Sys.getenv("RVAR_URL"), "/de/")[[1]][1], links)

out$url <- can_links

# fix column order
out <- out[, c("id", "from_date", "from_time", "from_weekday", "to_date", "to_time", "to_weekday", "event", "url", "created_at")]

# Add a testevent
out <- create_testevent()

con <- con_sau()

dbExecute(con, "DROP TABLE IF EXISTS temp_events")
dbWriteTable(con, name = "temp_events", value = out)

# Recreate from scratch
# dbExecute(con, "DROP TABLE IF EXISTS events")
# dbWriteTable(con, name = "events", value = out)

# Check for new entries!
ids <- dbGetQuery(con, "select distinct id from events")

new <- out$id[!out$id %in% ids$id]

check <- length(new) > 0

# Add new events and report
if (check) {
  add <- out[out$id %in% new, ]
  
  send_signal("\"Neues Sau Event entdeckt\"")
  
  for (i in seq_len(nrow(add))) {
    chr_url <- add$url[i]
    send_signal(chr_url)
  }
  
  send_signal("\"Ende der Übertragung!\"")
  
  nn <- dbAppendTable(con, name = "events", value = add)
}

# display all events
dd <- dbGetQuery(con, "select * from events")
kable(dd)

dbDisconnect(con)
