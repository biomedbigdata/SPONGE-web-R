#' Find All Possible ceRNA Interactions Between Identifiers
#'
#' @description Get all interactions between the given identifiers (ensg_number or gene_symbol).
#'
#' @param disease_name Name of the specific cancer type/dataset. If default is set, all available datasets with corresponding informations are shown.
#'                     Fuzzy search available.
#' @param ensg_number A vector of ensg number(s). If ensg number is set, gene symbol and gene type must be NULL. One of the three identifiers must be provided.
#' @param gene_symbol A vector of gene symbol(s). If gene symbol is set, ensg number and gene type must be NULL. One of the three identifiers must be provided.
#' @param limit Number of results that should be shown. Default value is 100 and can be up to 1000.
#'              For more results please use batches, the provided offset parameter or download the whole dataset.
#' @param offset Starting point from where results should be shown.
#'
#' @return A data_frame containing all interactions between genes of interest.
#' @export
#'
#' @importFrom jsonlite fromJSON
#' @importFrom utils URLencode
#' @importFrom dplyr mutate_at %>%
#' @importFrom httr GET content headers
#'
#' @examples
#' get_specific_ceRNAInteractions(disease_name = "kidney clear cell carcinoma",
#'                                ensg_number = c("ENSG00000259090","ENSG00000217289","ENSG00000152284"))
#'\dontrun{
#' # Do not use both identifiers at the same time
#' get_specific_ceRNAInteractions(disease_name = "kidney clear cell carcinoma",
#'                                ensg_number = c("ENSG00000259090","ENSG00000217289","ENSG00000152284"),
#'                                gene_symbol = c("SEPT7P1","TIGAR"))
#'}
get_specific_ceRNAInteractions <- function(disease_name = NULL,
                                       ensg_number = NULL,
                                       gene_symbol = NULL,
                                       limit = 100,
                                       offset = NULL){
  # all checks will be done from the API and its unit tests!

  # Base URL path
  base_url = "http://10.162.163.20:5000/ceRNAInteraction/findSpecific?"
  full_url = base_url

  # Create full url
  if (!is.null(disease_name)){
    full_url = paste(full_url, "disease_name=", disease_name,"&", sep="")
  }
  if (!is.null(ensg_number)){
    full_url = paste(full_url, "ensg_number=", paste(ensg_number, collapse=",", sep=""), "&", sep="")
  }
  if(!is.null(gene_symbol)) {
    full_url = paste(full_url, "gene_symbol=", paste(gene_symbol, collapse=",", sep=""), "&", sep="")
  }
  if (!is.null(limit)){
    full_url <- paste(full_url, "limit=", limit, "&", sep="")
  }
  if(!is.null(offset)){
    full_url <- paste(full_url, "offset=", offset, "&", sep="")
  }

  # Encode the URL with characters for each space.
  full_url <- URLencode(full_url)

  # Convert to text object using httr
  url_obj <- GET(full_url)

  # Parse url object
  raise <- content(url_obj, as="text", encoding = "UTF-8")

  #parse JSON
  new <- fromJSON(raise)

  # Determine if a url object returns '404 Not Found'
  if(headers(url_obj)$`content-type` == "application/problem+json")
    stop(paste("API response is empty. Reason: ", new$detail))
  else {
    # Flatten out nested elements
    new <- do.call("data.frame", do.call("data.frame", new))

    # Turn columns to numeric and remove NA values
    new <- new %>%
      mutate_at(c("correlation", "p_value", "mscor", "run.dataset.dataset_ID", "run.run_ID"), as.numeric) %>%
      mutate_at(c("gene1.ensg_number", "gene1.gene_symbol", "gene2.ensg_number", "gene2.gene_symbol"), as.character)
    return(new)
  }
}