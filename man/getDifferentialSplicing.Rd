% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/globalAccess.R
\name{getDifferentialSplicing}
\alias{getDifferentialSplicing}
\alias{setDifferentialSplicing}
\alias{getDifferentialSplicingFiltered}
\alias{setDifferentialSplicingFiltered}
\alias{getDifferentialSplicingSurvival}
\alias{setDifferentialSplicingSurvival}
\alias{getDifferentialSplicingResetPaging}
\alias{setDifferentialSplicingResetPaging}
\alias{getDifferentialSplicingColumns}
\alias{setDifferentialSplicingColumns}
\title{Get or set differential splicing' elements for a data category}
\usage{
getDifferentialSplicing(category = getCategory())

setDifferentialSplicing(differential, category = getCategory())

getDifferentialSplicingFiltered(category = getCategory())

setDifferentialSplicingFiltered(differential, category = getCategory())

getDifferentialSplicingSurvival(category = getCategory())

setDifferentialSplicingSurvival(survival, category = getCategory())

getDifferentialSplicingResetPaging(category = getCategory())

setDifferentialSplicingResetPaging(reset, category = getCategory())

getDifferentialSplicingColumns(category = getCategory())

setDifferentialSplicingColumns(columns, category = getCategory())
}
\arguments{
\item{category}{Character: data category}

\item{differential}{Data frame or matrix: differential analyses table}

\item{survival}{Data frame or matrix: differential analyses' survival data}

\item{reset}{Character: reset paging of differential analyses table?}

\item{columns}{Character: differential analyses' column names}
}
\value{
Getters return globally accessible data, whereas setters return
\code{NULL} as they are only used to modify the Shiny session's state
}
\description{
Get or set differential splicing' elements for a data category
}
\note{
Needs to be called inside a reactive function
}
\seealso{
Other functions to get and set global variables: 
\code{\link{getClinicalMatchFrom}()},
\code{\link{getDifferentialExpression}()},
\code{\link{getGlobal}()},
\code{\link{getGroups}()},
\code{\link{getHighlightedPoints}()},
\code{\link{getSelectedDataPanel}()}
}
\concept{functions to get and set global variables}
\keyword{internal}
