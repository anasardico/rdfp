#' Transmit and Receive API SOAP Calls
#' 
#' Pull together SOAP Header and Body and 
#' make call to the appropriate API service, then 
#' parse the response.
#' 
#' @importFrom XML xmlTreeParse xmlToList xmlChildren xmlRoot xmlValue newXMLTextNode
#' @importFrom httr POST content
#' @include dfp_auth.R
#' @param body a character string of XML with service name
#' as an attribute
#' @param service a character string matching one of the API
#' services
#' @param network_code a character string matching the code 
#' associated with the ad serving network
#' @param application_name a character string naming your
#' application so that it can be identified in API calls
#' @param version a character string indicating the version of the DFP API 
#' that is to be used in the SOAP request
#' @param verbose a logical indicating whether to print the POSTed XML
#' @return a XML document if no error was returned
#' 
#' @keywords internal
build_soap_request <- function(body, service = NULL,
                               network_code=getOption("rdfp.network_code"), 
                               application_name=getOption("rdfp.application_name"),
                               version=getOption("rdfp.version"),
                               verbose=FALSE){
  
  if (is.null(service)){
    service <- attributes(body)$service
  }

  header <- paste0('<?xml version="1.0" encoding="UTF-8"?> 
<soapenv:Envelope
 xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
 xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 <soapenv:Header>
   <ns1:RequestHeader
     soapenv:actor="http://schemas.xmlsoap.org/soap/actor/next"
     soapenv:mustUnderstand="0"
     xmlns:ns1="https://www.google.com/apis/ads/publisher/', version, '">
       <ns1:networkCode>', network_code, '</ns1:networkCode>
       <ns1:applicationName>', application_name, '</ns1:applicationName>
   </ns1:RequestHeader>
 </soapenv:Header>')
  
  soap_body <- paste0("<soapenv:Body>\n  ", 
                        body,
                     "  \n</soapenv:Body>\n ")
  
  env_close <- '</soapenv:Envelope>' 
  
  this_body <- paste0(header, ' \n ', soap_body, ' \n', env_close)
  
  url <- paste0('https://ads.google.com/apis/ads/publisher/', version, '/', service)

  if(verbose){
    print(url)
    print(newXMLTextNode(this_body))
  }
  
  #use xml2 package ?
  req <- POST(url=url, config=get_google_token(), body=this_body)
  text_response <- xmlTreeParse(content(req, as = "text", encoding = "UTF-8"))
  
  # check for curl errors
  doc_error <- text_response$doc$children$Error
  if(!is.null(doc_error)){
    print(doc_error)
    stop("curl error", call. = FALSE)
  }

  if(is.null(xmlChildren(xmlRoot(text_response))$Body)){
    return(NULL)
  }
  
  # check for api fault errors
  api_fault <- xmlChildren(xmlChildren(xmlRoot(text_response))$Body)$Fault
  
  if(!is.null(api_fault)){
#    print(api_fault)
    more_detail <- xmlChildren(api_fault)
    if('faultcode' %in% names(more_detail)){
      faultstring <-  xmlValue(xmlChildren(api_fault)$faultstring)
      if(!is.null(faultstring)){
        message(paste0('faultstring: ', faultstring))
      } else {
        faultstring <- ''
      }
    }
    if('detail' %in% names(more_detail)){
      errorString <-  xmlValue(xmlChildren(api_fault)$errorString)
      if(!is.null(errorString)){
        message(paste0('errorString: ', errorString))
      } else {
        errorString <- ''
      }
      reason <-  xmlValue(xmlChildren(api_fault)$reason)
      if(!is.null(reason)){
        message(paste0('reason: ', reason))
      } else {
        reason <- ''
      }
    }
    stop(paste0('api fault: ', faultstring, errorString, reason, collapse='\n'), call. = F)
  }
  return(text_response)
}


#' Build XML Request Body
#' 
#' Parse data into XML format
#' 
#' @importFrom XML newXMLNode xmlValue<-
#' @param list a \code{list} of data to fill the XML body
#' @param root_name a character string to be put in the 
#' topmost level of the created XML hierarchy
#' @param root a XML node to be placed as root 
#' in the returned XML document
#' @param version a character string indicating the version of the DFP API 
#' that is to be used in the SOAP request
#' @return a XML document
#' 
#' @keywords internal
build_xml_from_list <- function(list, root_name=NULL, 
                                root=NULL, version=getOption("rdfp.version")){

  if (is.null(root))
    root <- newXMLNode(root_name, 
                       namespaceDefinitions = 
                         c(paste0("https://www.google.com/apis/ads/publisher/", 
                                  version)))
  
  if(length(list)>0){

    for (i in 1:length(list)){
      
      if('.attrs' %in% names(list[[i]])){
        incl_type <- list[[i]][['.attrs']]
        names(incl_type) <- 'xsi:type'
        list[[i]][['.attrs']] <- NULL
      } else if (grepl('[a-zA-Z]+Action$|^action$', names(list)[i])) {
        incl_type <- list[[i]]
        names(incl_type) <- 'xsi:type'
        list[[i]] <- ''
      } else {
        incl_type <- NULL
      }
      
      if (typeof(list[[i]]) == "list") {
        this <- newXMLNode(names(list)[i], 
                           attrs=incl_type, 
                           parent=root,
                           suppressNamespaceWarning=T)
        build_xml_from_list(list=list[[i]], root=this)
      }
      else {
        if (!is.null(list[[i]])){
          this <- newXMLNode(names(list)[i], 
                             attrs=incl_type, 
                             parent=root,
                             suppressNamespaceWarning=T)
          xmlValue(this) <- list[[i]]
        }
      }
    }
  }
  
  return(root)
}


#' Format SOAP Request Body
#' 
#' Receive data for a service and build the Body of text 
#' to include in a SOAP request.
#' 
#' @importFrom plyr alply
#' @importFrom methods as
#' @param service a character string matching one of the API
#' services
#' @param root_name a character string to be put in the 
#' topmost level of the created XML hierarchy
#' @param data a \code{list} or \code{data.frame} to create
#' XML in the request
#' @return a character string of XML with service name
#' as an attribute
#' 
#' @keywords internal
make_request_body <- function(service, root_name, data=NULL){

  if(!is.null(data)){
    if(is.data.frame(data)){
      data <- alply(data, 1, function(x){as.list(data.frame(x))})
      attributes(data) <- NULL
    } else if(!is.list(data)){
      stop('data must be a list or data.frame')
    }
  }
  
  if (grepl('^create|^update', root_name)){
    record_names <- gsub('CustomTargeting', '', gsub('create|update', '', root_name))
    names(data) <- rep(gsub("(^[[:alpha:]])", "\\L\\1", record_names, perl=TRUE), length(data))
  }
  if (root_name=='getCustomFieldOption'){
    data <- as.list(data.frame(data))
    names(data) <- rep('customFieldOptionId', length(data))
  }
  
  xml_body <- build_xml_from_list(data, root_name=root_name)
  request_body <- as(xml_body, 'character')
  attributes(request_body) <- list('service'=service)
  
  return(request_body)
}

#' Take report URL and convert to data.frame
#' 
#' Receive a URL (usually from the ReportService) and 
#' download data from that URL. Currently, the exportFormat
#' must have been set for CSV_DUMP
#' 
#' @usage dfp_report_url_to_dataframe(report_url, exportFormat='CSV_DUMP')
#' @importFrom curl curl_download
#' @importFrom utils read.table
#' @param report_url a URL character string returned from the 
#' function \link{dfp_getReportDownloadURL}
#' @param exportFormat a character string naming what type of exportFormat was 
#' provided to \link{dfp_getReportDownloadURL}. This is used to determine how to parse the results.
#' @return a \code{data.frame} of report results from the specified URL
#' 
#' @export
dfp_report_url_to_dataframe <- function(report_url, exportFormat='CSV_DUMP'){
  
  stopifnot(exportFormat %in% c('CSV_DUMP', 'TSV', 'CSV_EXCEL'))
  
  # setup encoding and sep, very limited at this point
  if (exportFormat=='CSV_DUMP'){
    this_encoding <- 'UTF-8'
    this_sep <- ','
    this_quote <- '"'
  } else if (exportFormat=='TSV'){
    this_encoding <- 'UTF-8'
    this_sep <- '\t'
    this_quote <- '"'
  } else {
    this_encoding <- 'UTF-8'
    this_sep <- ','
    this_quote <- '"'
  }
  
  temp_destination <- tempfile()
  curl_download(url=report_url, destfile=temp_destination)
  report_dat <- read.table(gzfile(temp_destination, encoding=this_encoding), header = T, comment.char = "",
                           fileEncoding=this_encoding, sep=this_sep, quote=this_quote)
  return(report_dat)
}


#' Take report request and return data.frame
#' 
#' Take a report request and manage all aspects for user
#' until returning a data.frame or error
#' 
#' @usage dfp_full_report_wrapper(request_data, 
#'                                check_interval=3, 
#'                                max_tries=10, 
#'                                verbose=FALSE)
#' @param request_data a \code{list} or \code{data.frame} of data elements
#' to be formatted for a SOAP 
#' request (XML format, but passed as character string)
#' @param check_interval a numeric specifying seconds to wait between report 
#' status requests to check if complete
#' @param max_tries a numeric specifying the maximum number of times to check 
#' whether the report is complete before the function essentially times out
#' @param verbose a logical indicating whether to print the report URL
#' @return a \code{data.frame} of report results as specified by the request_data
#' 
#' @seealso \link{dfp_runReportJob} 
#' @seealso \link{dfp_getReportJobStatus}
#' @seealso \link{dfp_getReportDownloadURL}
#' @export
dfp_full_report_wrapper <- function(request_data, 
                                    check_interval=3, 
                                    max_tries=10, 
                                    verbose=FALSE){
  
  dfp_runReportJob_result <- dfp_runReportJob(request_data, as_df=F)$rval
  
  status_request_data <- list(reportJobId=dfp_runReportJob_result$id)
  dfp_getReportJobStatus_result <- dfp_getReportJobStatus(status_request_data, as_df=F)$rval
  
  counter <- 0
  while(dfp_getReportJobStatus_result != 'COMPLETED' & counter < max_tries){
    dfp_getReportJobStatus_result <- dfp_getReportJobStatus(status_request_data, as_df=F)$rval
    Sys.sleep(check_interval)
    counter <- counter + 1
  }
  
  stopifnot(dfp_getReportJobStatus_result=='COMPLETED')
  
  url_request_data <- list(reportJobId=dfp_runReportJob_result$id, exportFormat='CSV_DUMP')
  dfp_getReportDownloadURL_result <- dfp_getReportDownloadURL(url_request_data, as_df=F)$rval
  if(verbose){
    print(dfp_getReportDownloadURL_result)
  }
  report_dat <- dfp_report_url_to_dataframe(report_url=dfp_getReportDownloadURL_result)
  
  return(report_dat)
  
}


#' Take select request and return data.frame
#' 
#' Take a select request result from the 
#' PublishersQueryLanguage service and parse into a data.frame
#' 
#' @usage dfp_select_parse(result_data)
#' @importFrom plyr ldply
#' @param result_data a \code{list} returned from \link{dfp_select}
#' @return a \code{data.frame} of report results as specified by the result_data
#' 
#' @seealso dfp_select 
#' @export
dfp_select_parse <- function(result_data){
  
  these_names <- unlist(result_data[grepl('columnTypes', names(result_data))], 
                        use.names = F)
  these_types <- unlist(result_data[['rows']]['.attrs',], use.names = F)
  these_rows <- ldply(result_data[grepl('rows', names(result_data))], 
                      .fun=function(x){
                        x <- x['value',]
                        names(x) <- these_names
                        new_x <- as.data.frame(t(x), stringsAsFactors = F)
                        return(new_x)
                      }, .id=NULL)
  these_rows <- sapply(these_rows, as.character, simplify = F)
  result_set <- data.frame(these_rows)
  suppressWarnings(result_set[,c(which(these_types=='NumberValue'))] <- sapply(result_set[,c(which(these_types=='NumberValue'))], as.numeric))
  
  return(result_set)
}
