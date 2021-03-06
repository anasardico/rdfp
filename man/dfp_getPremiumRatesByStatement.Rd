% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/PremiumRateService.R
\name{dfp_getPremiumRatesByStatement}
\alias{dfp_getPremiumRatesByStatement}
\title{getPremiumRatesByStatement}
\usage{
dfp_getPremiumRatesByStatement(request_data, as_df = TRUE, verbose = FALSE)
}
\arguments{
\item{request_data}{a \code{list} or \code{data.frame} of data elements
to be formatted for a SOAP
request (XML format, but passed as character string)}

\item{as_df}{a boolean indicating whether to attempt to parse the result into
a \code{data.frame}}

\item{verbose}{a boolean indicating whether to print the service URL and POSTed XML}
}
\value{
a \code{data.frame} or \code{list} containing all the elements of a getPremiumRatesByStatementResponse
}
\description{
Gets a PremiumRatePage of PremiumRate objects that satisfy the given Statement query. The following fields are supported for filtering: 
\itemize{
  \item{id}
  \item{rateCardId}
  \item{pricingMethod}
}
}
\seealso{
\href{https://developers.google.com/doubleclick-publishers/docs/reference/v201711/PremiumRateService#getPremiumRatesByStatement}{Google Documentation for getPremiumRatesByStatement}
}
