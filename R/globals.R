# Declare global variables to avoid R CMD check notes
# These are column names used in NSE (non-standard evaluation)

globalVariables(c(
  "embedding",
  "n_dims",
  "text",
  ".input_idx",
  ".error",
  ".error_msg",
  "similarity"
))
