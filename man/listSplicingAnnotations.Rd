% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_inclusionLevels.R
\name{listSplicingAnnotations}
\alias{listSplicingAnnotations}
\title{List alternative splicing annotations}
\usage{
listSplicingAnnotations(
  species = NULL,
  assembly = NULL,
  date = NULL,
  cache = getAnnotationHubOption("CACHE"),
  group = FALSE
)
}
\arguments{
\item{species}{Character: filter results by species (regular expression)}

\item{assembly}{Character: filter results by assembly (regular expression)}

\item{date}{Character: filter results by date (regular expression)}

\item{cache}{Character: path to \code{AnnotationHub} cache (used to load
alternative splicing event annotation)}

\item{group}{Boolean: group values based on data provider?}
}
\value{
Named character vector with splicing annotation names
}
\description{
List alternative splicing annotations
}
\examples{
listSplicingAnnotations() # Return all alternative splicing annotations
listSplicingAnnotations(assembly="hg19") # Search for hg19 annotation
listSplicingAnnotations(assembly="hg38") # Search for hg38 annotation
listSplicingAnnotations(date="201(7|8)") # Search for 2017 or 2018 annotation
}
\seealso{
Other functions for PSI quantification: 
\code{\link{filterPSI}()},
\code{\link{getSplicingEventTypes}()},
\code{\link{loadAnnotation}()},
\code{\link{plotRowStats}()},
\code{\link{quantifySplicing}()}
}
\concept{functions for PSI quantification}
