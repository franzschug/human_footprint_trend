iblkrow <- function(a, chunks) {
  n <- nrow(a)
  i <- 1
  
  nextElem <- function() {
    if (chunks <= 0 || n <= 0) stop('StopIteration')
    m <- ceiling(n / chunks)
    r <- seq(i, length=m)
    i <<- i + m
    n <<- n - m
    chunks <<- chunks - 1
    a[r,, drop=FALSE]
  }
  
  structure(list(nextElem=nextElem), class=c('iblkrow', 'iter'))
}
nextElem.iblkrow <- function(obj) obj$nextElem()
