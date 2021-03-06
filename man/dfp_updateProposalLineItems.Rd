% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ProposalLineItemService.R
\name{dfp_updateProposalLineItems}
\alias{dfp_updateProposalLineItems}
\title{updateProposalLineItems}
\usage{
dfp_updateProposalLineItems(request_data, as_df = TRUE, verbose = FALSE)
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
a \code{data.frame} or \code{list} containing all the elements of a updateProposalLineItemsResponse
}
\description{
Updates the specified ProposalLineItem objects. If free editing mode is enabled, this will trigger inventory reservation and cause the proposal to be pushed to DFP again.
}
\seealso{
\href{https://developers.google.com/doubleclick-publishers/docs/reference/v201711/ProposalLineItemService#updateProposalLineItems}{Google Documentation for updateProposalLineItems}
}
