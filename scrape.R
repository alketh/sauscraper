library(rvest)
library(stringr)
library(tibble)

url <- "https://www.salzwasserunion.de/de/sau-in-aktion/veranstaltungen/cat.listevents"

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
