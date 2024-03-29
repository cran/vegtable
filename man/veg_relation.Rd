% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/veg_relation.R
\name{veg_relation}
\alias{veg_relation}
\alias{veg_relation,vegtable,character-method}
\alias{veg_relation<-}
\alias{veg_relation<-,vegtable,data.frame-method}
\title{Retrieve or replace relations in vegtable objects}
\usage{
veg_relation(vegtable, relation, ...)

\S4method{veg_relation}{vegtable,character}(vegtable, relation, match_header = FALSE, ...)

veg_relation(vegtable) <- value

\S4method{veg_relation}{vegtable,data.frame}(vegtable) <- value
}
\arguments{
\item{vegtable}{An object of class \linkS4class{vegtable}.}

\item{relation}{A character value indicating the relation table to be
retrieved or replaced.}

\item{...}{Further arguments to be passed among methods.}

\item{match_header}{A logical vector, whether only levels occurring in slot
\code{header} should be considered or all.}

\item{value}{A data frame containing the new veg_relation.}
}
\value{
This function retrieves and object of class \code{data.frame}.
In the replacement method, an object of class \linkS4class{vegtable}, including
\code{value} in the slot \code{relations}.
}
\description{
Tables providing information about levels of categorical variables in the
header are called \code{popups} in \strong{Turboveg} databases
but \code{relations} in \linkS4class{vegtable} objects.
Such variables will be converted into factors in the slot \code{header} according
to the levels and their sorting in the respective relation.
}
\examples{
## overview of references
veg_relation(Kenya_veg, "REFERENCE")

}
\author{
Miguel Alvarez \email{kamapu78@gmail.com}
}
