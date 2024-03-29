#' @exportMethod cover_trans
#'
setGeneric("cover_trans", function(x, conversion, ...) {
  standardGeneric("cover_trans")
})

#' @name cover_trans
#'
#' @title Convert cover scales to percent cover
#'
#' @description
#' Convert values of a categorical cover scale to percentage values.
#'
#' This function requires as input a [coverconvert-class] object which contains
#' the conversion tables.
#'
#' @param x Either a factor or character vector, or a [vegtable-class] object.
#' @param conversion An object of class [vegtable-class].
#' @param from Scale name of values in `x` as character value.
#' @param to Name of the column in slot `samples` for writing converted values.
#' @param replace Logical value indicating whether existing cover values should
#'     be replaced by the new computed values or not.
#' @param rule A character value indicating the rule applied for cover
#'     transformation. Three rules are implemented for transformation,
#'     either `top` (values transformed to the top of the range),
#'     `middle` (transformation at the midpoint), and
#'     `bottom` (conversion at the lowest value of the range).
#'     In the later case, if the bottom is zero cover, a fictive bottom value
#'     can be set by `'zeroto'`
#' @param zeroto Value set for transformation of classes with bottom at 0%
#'     cover.
#' @param ... Further arguments passed from or to other methods.
#'
#' @return Either a vector or a [vegtable-class] object.
#'
#' @author Miguel Alvarez \email{kamapu78@@gmail.com}
#'
#' @examples
#' ## Check the available scales
#' summary(Kenya_veg@coverconvert)
#'
#' ## Conversion by default 'top' rule
#' Kenya_veg <- cover_trans(Kenya_veg, to = "percent")
#' summary(as.factor(Kenya_veg@samples$percent))
#'
#' ## Conversion by 'middle' rule
#' Kenya_veg <- cover_trans(Kenya_veg, to = "percent", rule = "middle", replace = TRUE)
#' summary(as.factor(Kenya_veg@samples$percent))
#'
#' ## Conversion by 'bottom' rule
#' Kenya_veg <- cover_trans(Kenya_veg, to = "percent", rule = "bottom", replace = TRUE)
#' summary(as.factor(Kenya_veg@samples$percent))
#' @rdname cover_trans
#'
#' @aliases cover_trans,character,coverconvert-method
#'
setMethod(
  "cover_trans", signature(
    x = "character",
    conversion = "coverconvert"
  ),
  function(x, conversion, from = NULL, rule = "top", zeroto = 0.1, ...) {
    rule <- grep(rule[1], c("top", "bottom", "middle"), ignore.case = TRUE)
    if (!rule %in% c(1:3)) {
      stop("Invalid value for argument 'rule'")
    }
    if (any(!x %in% base::levels(conversion@value[[from]]))) {
      warning(paste(
        "Some values in 'x' are not valid and will be",
        "converted in NAs"
      ))
    }
    top <- conversion@conversion[[from]][-1][match(
      x,
      base::levels(conversion@value[[from]])
    )]
    if (rule == 1) {
      return(top)
    } else {
      ties <- rev(duplicated(rev(conversion@conversion[[from]])))
      bottom <- conversion@conversion[[from]][-length(
        conversion@conversion[[from]]
      )]
      for (i in 1:length(bottom)) {
        if (ties[i]) {
          bottom[i] <- bottom[i - 1]
        }
      }
      bottom <- bottom[match(
        x,
        base::levels(conversion@value[[from]])
      )]
      if (rule == 3) {
        return((bottom + top) / 2)
      }
      if (rule == 2) {
        bottom[bottom == 0] <- zeroto
        return(bottom)
      }
    }
  }
)

#' @rdname cover_trans
#'
#' @aliases cover_trans,factor,coverconvert-method
setMethod(
  "cover_trans", signature(
    x = "factor",
    conversion = "coverconvert"
  ),
  function(x, conversion, ...) {
    x <- paste(x)
    cover_trans(x, conversion, ...)
  }
)

#' @rdname cover_trans
#'
#' @aliases cover_trans,numeric,coverconvert-method
setMethod(
  "cover_trans", signature(
    x = "numeric",
    conversion = "coverconvert"
  ),
  function(x, conversion, ...) {
    x <- paste(x)
    cover_trans(x, conversion, ...)
  }
)

#' @rdname cover_trans
#'
#' @aliases cover_trans,vegtable,missing-method
setMethod(
  "cover_trans", signature(x = "vegtable", conversion = "missing"),
  function(x, to, replace = FALSE, rule = "top", zeroto = 0.1,
           ...) {
    if (!to %in% colnames(x@samples)) x@samples[, to] <- NA
    if (replace) {
      Selection <- 1:length(x@samples[, to])
    } else {
      Selection <- which(is.na(x@samples[, to]))
    }
    for (i in names(x@coverconvert)) {
      if (i %in% colnames(x@samples)) {
        Selection2 <- which(!is.na(x@samples[, i]))
        Selection2 <- intersect(Selection, Selection2)
        x@samples[Selection2, to] <-
          cover_trans(x@samples[Selection2, i],
            x@coverconvert,
            from = i, rule = rule,
            zeroto = zeroto
          )
      }
    }
    return(x)
  }
)
