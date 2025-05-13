# Search in PubMed

```R
# load libraries
library(rentrez)
library(xml2)

# set NCBI API key to increase rate limits
Sys.setenv(ENTREZ_KEY="your/key")

# 1. Define search query

query <- paste0(
  '((“Chiroptera”[MeSH Terms] OR chiroptera[TIAB] OR bat[TIAB] OR bats[TIAB]) ',
  'AND (“Metagenomics”[MeSH Terms] OR metagenomic[TIAB] OR metagenomics[TIAB] ',
  'OR microbiome[TIAB] OR microbiota[TIAB]) ',
  'AND (“Bacteria”[MeSH Terms] OR bacteria[TIAB]) ',
  'AND ("2020/01/01"[DP] : "2025/12/31"[DP]) ',
  'NOT (“Virus”[MeSH Terms])'
)

query2 <- paste0(
  'TITLE:(bat OR chiroptera) ',
  'AND (ABSTRACT:(metagenom* OR metagenomic* OR microbiome* OR microbiota*)) ',
  'AND KEY:(bacteria) ',
  'AND PUB_TYPE:"Research Article" ',
  'AND PUB_YEAR:[2020 TO 2025] ',
  'NOT KEY:virus'
)

# 1. Search PubMed, store history
search_res <- entrez_search(
  db          = "pubmed",
  term        = query,
  use_history = TRUE,
  retmax      = 500    # enough to cover all possible hits
)

cat("Total hits:", search_res$count, "\n")  
# Likely ~83

# 2. Fetch all records via history
fetch_res <- entrez_fetch(
  db          = "pubmed",
  web_history = search_res$web_history,
  rettype     = "xml",
  retmax      = search_res$count
)

# 3. Parse XML and extract DOI
doc      <- read_xml(fetch_res)
articles <- xml_find_all(doc, ".//PubmedArticle")

# Initialize all columns as zero-length
out <- data.frame(
  PMID     = character(),
  DOI      = character(),
  Source   = character(),
  title    = character(),
  abstract = character(),
  stringsAsFactors = FALSE
)

# 2. Loop through each article
for (art in articles) {
  # Extract PMID
  pmid <- xml_text(xml_find_first(art, ".//PMID"))
  
  # Extract DOI
  doi_node <- xml_find_first(art, ".//ArticleId[@IdType='doi']")
  doi      <- if (!is.na(doi_node)) xml_text(doi_node) else NA_character_
  
  # Extract title
  title_node <- xml_find_first(art, ".//ArticleTitle")
  title      <- if (!is.na(title_node)) xml_text(title_node) else NA_character_
  
  # Extract and concatenate all sections of the abstract
  abstract_nodes <- xml_find_all(art, ".//AbstractText")
  abstract_text  <- if (length(abstract_nodes)>0) {
    paste(xml_text(abstract_nodes), collapse = " ")
  } else {
    NA_character_
  }
  
  # Add row to the data frame
  out <- rbind(
    out,
    data.frame(
      title    = title,
      abstract = abstract_text,
      Source   = "PubMed",
      DOI      = doi,
      stringsAsFactors = FALSE
    )
  )
}

df_bats3 <- data.frame(
  title    = out$title,
  abstract = out$abstract,
  source = out$Source,
  DOI = out$DOI
)

# write table
write.table(df_bats3, "bat_pubmed.csv", row.names = FALSE, sep = ";")
```




# Search in Crossref

```R

# load libraries
library(rcrossref)
library(dplyr)
library(purrr)

# prepare query
meta <- cr_works(query = query, filter = c(from_pub_date = "2020-01-01"))
total_results <- meta$meta$total_results
print(paste("Total available results:", total_results))

# download

# First page (100)
results_1 <- cr_works(query = query2, filter = c(from_pub_date = "2020-01-01"), limit = 100)

# Second page (100)
results_2 <- cr_works(query = query2, filter = c(from_pub_date = "2020-01-01"), limit = 100, offset = 100)

# Third page (100)
results_3 <- cr_works(query = query2, filter = c(from_pub_date = "2020-01-01"), limit = 100, offset = 200)

length(results_2$data$doi)

# Initialize a vector to store each cleaned line
cleaned_lines <- character(length(results_3$data$abstract))

# For loop to process line by line
for (i in seq_along(results_3$data$abstract)) {
  line <- results_3$data$abstract[i]
  
  # Clean: remove XML/HTML tags
  text <- gsub("<[^>]+>", "", line)
  
  # Clean multiple spaces and trim start/end
  text <- trimws(gsub("\\s+", " ", text))
  
  # Save the cleaned line
  cleaned_lines[i] <- text
}

# Result: vector 'cleaned_lines' with one clean line per position
print(cleaned_lines)


df_bats <- data.frame(
    title    = results_3$data$title,     
    abstract = cleaned_lines,
    source = "rcrossref",
    DOI      = results_3$data$doi
  )


# 3. View first rows
head(df_bats)

# write table
write.table(df_bats, "bat_crossref.csv", row.names = FALSE, sep = ";")
```




# Search in Europe PMC
```R
# load librarie
library(europepmc)

# 1. Run query (adjust 'limit' to cover all hits)
res <- epmc_search(
  query = query2,
  limit = 3000,
  output = "raw"
)


class(res)         # likely a list
length(res)        # how many elements it has

if (length(res) > 0) {str(res[[18]], max.level = 6)}


# extract titles

titles <- sapply(res, function(x) x$title)
head(titles)

# abstract
abstracts <- sapply(res, function(x) if (!is.null(x$abstract)) x$abstract else NA_character_)

cleaned_lines2 <- character(length(abstracts))

# For loop to process line by line
for (i in seq_along(abstracts)) {
  line <- abstracts[i]
  
  # Clean: remove XML/HTML tags
  text <- gsub("<[^>]+>", "", line)
  
  # Clean multiple spaces and trim start/end
  text <- trimws(gsub("\\s+", " ", text))
  
  # Save the cleaned line
  cleaned_lines2[i] <- text
}
head(cleaned_lines2)

# doi
doi_ <- sapply(res, function(x) if (!is.null(x$doi)) x$doi else NA_character_)
head(doi_)


# 3. Build a clean data.frame with only DOI, title and abstract
df_bats2 <- data.frame(
  title    = titles,
  abstract = cleaned_lines2,
  source = "Europe PMC",
  DOI = doi_
)
               
# Write results to CSV
write.table(df_bats2, "bat_europmc.csv", row.names = FALSE, sep = ";")
```

               
# Combine tables
```R

table_1 <- rbind(df_bats3, df_bats2)
table_2 <- rbind(df_bats, table_1)

length(table_2$DOI)
duplicated(table_2$DOI)
table_3 <- table_2[!duplicated(table_2$DOI),]

# Write results to CSV
write.table(table_3, "bat_bacteria.csv", row.names = FALSE, sep = ";")
```
