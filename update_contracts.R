install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

install_if_missing("nhlscraper")
install_if_missing("httr2")
install_if_missing("jsonlite")
install_if_missing("dplyr")

library(nhlscraper)
library(httr2)
library(jsonlite)
library(dplyr)

web_app_url <- Sys.getenv("GOOGLE_WEB_APP_URL")
secret_key <- Sys.getenv("SHEETS_SECRET_KEY")

if (web_app_url == "") {
  stop("GOOGLE_WEB_APP_URL is missing.")
}

if (secret_key == "") {
  stop("SHEETS_SECRET_KEY is missing.")
}

contracts_raw <- nhlscraper::contracts()

contracts_clean <- contracts_raw %>%
  mutate(
    source = "nhlscraper",
    lastUpdated = as.character(Sys.time())
  )

# Conversion en matrice compatible Google Sheets
headers <- names(contracts_clean)
data_rows <- contracts_clean %>%
  mutate(across(everything(), ~ ifelse(is.na(.), "", as.character(.)))) %>%
  as.data.frame(stringsAsFactors = FALSE)

rows <- rbind(
  as.list(headers),
  unname(split(data_rows, seq(nrow(data_rows))))
)

payload <- list(
  secret = secret_key,
  sheetName = "Contrats_nhlscraper",
  rows = rows
)

response <- request(web_app_url) %>%
  req_method("POST") %>%
  req_body_json(payload, auto_unbox = TRUE) %>%
  req_perform()

cat(resp_body_string(response))
