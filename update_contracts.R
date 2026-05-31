library(nhlscraper)
library(httr2)
library(jsonlite)
library(dplyr)

message("Packages chargés correctement.")

web_app_url <- Sys.getenv("GOOGLE_WEB_APP_URL")
secret_key <- Sys.getenv("SHEETS_SECRET_KEY")

if (web_app_url == "") {
  stop("GOOGLE_WEB_APP_URL is missing.")
}

if (secret_key == "") {
  stop("SHEETS_SECRET_KEY is missing.")
}

message("Téléchargement des contrats avec nhlscraper...")

contracts_raw <- nhlscraper::contracts()

message("Nombre de lignes reçues : ", nrow(contracts_raw))
message("Nombre de colonnes reçues : ", ncol(contracts_raw))

contracts_clean <- contracts_raw %>%
  mutate(
    source = "nhlscraper",
    lastUpdated = as.character(Sys.time())
  )

headers <- names(contracts_clean)

data_rows <- contracts_clean %>%
  mutate(across(everything(), ~ ifelse(is.na(.), "", as.character(.)))) %>%
  as.data.frame(stringsAsFactors = FALSE)

rows <- c(
  list(as.character(headers)),
  unname(split(data_rows, seq(nrow(data_rows))))
)

payload <- list(
  secret = secret_key,
  sheetName = "Contrats_nhlscraper",
  rows = rows
)

message("Envoi des données vers Google Sheets...")

response <- request(web_app_url) %>%
  req_method("POST") %>%
  req_body_json(payload, auto_unbox = TRUE) %>%
  req_perform()

message("Réponse Google Apps Script :")
message(resp_body_string(response))
