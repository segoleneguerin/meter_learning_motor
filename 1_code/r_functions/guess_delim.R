# To help determine whether the file is comma- or semicolon-separated

guess_delim <- function(file) {
  first_line <- readLines(file, n = 1)  # Read the first line
  if (grepl(";", first_line)) {
    return(";")
  } else {
    return(",")
  }
}