local({
  restore <- getOption("foundryR.doc_restore")
  if (is.function(restore)) {
    restore()
  }
  invisible(NULL)
})
