parse_time <- function(x) {
  out <- str_extract_all(string = x, pattern = "[0-9][0-9]:[0-9][0-9]")
  out <- out[[1]]
  
  if (length(out) == 2) out <- paste(out, collapse = "-")
  if (length(out) == 0) out <- NA
  
  out
}

parse_weekday <- function(x) {
  days <- c("Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag")
  out <- str_extract(x, pattern = days)
  out <- as.character(na.omit(out))
  
  if (length(out) == 0) out <- NA
  
  out
}

parse_date <- function(x) {
  months <- c("Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember")
  months_digit <- gsub(" ", "0", format(1:12, digits = 2))
  months_digit <- paste0(months_digit, ".")
  
  out <- str_replace(x, pattern = paste0(" ", months, " "), replacement = months_digit)
  nn <- nchar(out)
  out <- out[nn == min(nn)]
  
  res <- str_extract(out, pattern = "[0-9][0-9]\\.[0-9][0-9]\\.[0-9][0-9][0-9][0-9]")
  
  if (length(res) != 1) res <- NA
  
  res
}

con_sau <- function() {
  DBI::dbConnect(
    drv = RPostgres::Postgres(), 
    user = Sys.getenv("RVAR_DBUSER"), 
    password = Sys.getenv("RVAR_DBPASSWORD"), 
    host = Sys.getenv("RVAR_DBHOST"), 
    port = as.integer(Sys.getenv("RVAR_DBPORT")), 
    dbname = Sys.getenv("RVAR_DBNAME")
  )
}

create_testevent <- function() {
  fd <- Sys.Date()
  miss <- NA
  ev <- "testevent"
  
  id <- md5(paste(fd, miss, miss, fd, miss, miss, ev, collapse = "|"))
  
  tibble(
    id = id,
    from_date = fd,
    from_time = miss,
    from_weekday = miss,
    to_date = fd,
    to_time = miss,
    to_weekday = miss,
    event = ev,
    url = miss,
    created_at = Sys.time()
  )
}

send_signal <- function(x) {
  system2("signal-cli", args = c("-u", Sys.getenv("RVAR_SINGALNUMBER"), "send", "-g", Sys.getenv("RVAR_SIGNALGROUP"), "-m", x))
}

create_testevent_simple <- function() {
  tibble(
    url = paste0(strsplit(Sys.getenv("RVAR_URL"), "/de/")[[1]][1], "/this_is_a_test_event", runif(n = 1)),
    created_at = Sys.time()
  )
}

