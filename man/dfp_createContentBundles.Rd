% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ContentBundleService.R
\name{dfp_createContentBundles}
\alias{dfp_createContentBundles}
\title{ContentBundleService}
\usage{
dfp_createContentBundles(request_data, as_df = TRUE, verbose = FALSE)
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
a \code{data.frame} or \code{list} containing all the elements of a createContentBundlesResponse
}
\description{
Provides methods for creating, updating and retrieving ContentBundle
objects.
A ContentBundle is a grouping of Content that match filter
rules as well as taking into account explicitly included or excluded
Content.
}
\details{
createContentBundles

Creates new ContentBundle objects.
}
\seealso{
\href{https://developers.google.com/doubleclick-publishers/docs/reference/v201711/ContentBundleService#createContentBundles}{Google Documentation for createContentBundles}
}
