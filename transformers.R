# Transformers ----

# Transformers allow you to aply functions to the glue input and output,
# before and after evaluation.

# This allows you to write things like `glue::glue_sql()`,
# which automatically quotes variables for you or adds a syntax for
# collapsing outputs.


# The transformer functions take two arguments:
# - `text`: The unparsed string inside the glue block
# - `envir` The execution environment


# Most transformers will then call
# `eval(parse(text = text, keep.source = FALSE), envir)`
# which parses and evaluates the code.


# You can supply the transformer function to glue with the
# `.transformer` argument.

# In this way users can manipulate the text before parsing and 
# change the output after evaluation.


# It is often useful to write a `glue::glue()` wrapper function
# which supplies a `.transformer` to `glue::glue()` or
# `glue::glue_data()` and may have additional arguments.

# One important consideration when doing this is to include
# `.envir = parent.frame()` in the wrapper to ensure
# the evaluation environment is correct.


# The users are encouraged to create custom functions using
# transformers to fit their individual needs but may
# take the following examples as inspiration.
library(glue)


## Collapse transformer ----

# A transformer which automatically collapses any `glue` block ending in `*`.
collapse_transformer <- function(regex = "[*]$", ...) {
  function(text, envir) {
    collapse <- grep(pattern = regex, x = text)
    if (collapse) {
      text <- sub(pattern = regex, replacement = "", x = text)
    }
    res <- glue::identity_transformer(text = text, envir = envir)
    if (collapse) {
      return(glue::glue_collapse(x = res, ...))
    } else {
      return(res)
    }
  }
}


glue::glue("{1:5*}\n{letters[1:5]*}", .transformer = collapse_transformer(sep = ", "))
# 1, 2, 3, 4, 5
# a, b, c, d, e


glue::glue("{1:5*}\n{letters[1:5]*}", .transformer = collapse_transformer(sep = ", ", last = " and "))
# 1, 2, 3, 4 and 5
# a, b, c, d and e

x <- c("one", "two")
glue::glue("{x}: {1:5*}", .transformer = collapse_transformer(sep = ", "))
# Error
# one: 1, 2, 3, 4, 5
# two: 1, 2, 3, 4, 5


## Shell quoting transformer ----

# A transformer which automatically quotes variables for use in
# shell commands, e.g. via `system()` or `system2()`.
?system
?system2


shell_transformer <- function(type = c("sh", "csh", "cmd", "cmd2")) {
  type <- match.arg(type)
  function(text, envir) {
    res <- eval(parse(text = text, keep.source = FALSE), envir)
    shQuote(res)
  }
}


glue_sh <- function(..., .envir = parent.frame(), .type = c("sh", "csh", "cmd", "cmd2")) {
  .type <- match.arg(.type)
  glue::glue(..., .envir = .envir, .transformer = shell_transformer(.type))
}

filename <- "test"
writeLines(con = filename, text = "hello!")

command <- glue_sh("cat {filename}")
command
# cat "test"
system(command)
# hello!
# [1] 0


## emoji transformer ----

# A transformer that converts the text to the equivalent emoji.

emoji_transformer <- function(text, envir) {
  if (grepl(pattern = "[*]$", x = text)) {
    text <- sub(pattern = "[*]$", replacement = "", x = text)
    glue::glue_collapse(ji_find(text)$emoji)
  } else {
    ji(text)
  }
}

glue_ji <- function(..., .envir = parent.frame()) {
  glue::glue(..., .open = ":", .close = ":", .envir = .envir, .transformer = emoji_transformer)
}

glue_ji("one :heart:")
# one ❤️

glue_ji("many :heart*:")
# many ❤️❤️❤️❤️❤️❤️❤️❤️❤️


## sprintf transformer ----

# A transformer which allows succinct sprintf format strings.
sprintf_transformer <- function(text, envir) {
  m <- regexpr(pattern = ":.+$", text = text)
  if (m != -1) {
    format <- substring(regmatches(x = text, m = m), first = 2)
    regmatches(x = text, m = m) <- ""
    res <- eval(parse(text = text, keep.source = FALSE), envir)
    do.call(what = sprintf, args = list(glue::glue("%{format}"), res))
  } else {
    eval(parse(text = text, keep.source = FALSE), envir)
  }
}


glue_fmt <- function(..., .envir = parent.frame()) {
  glue::glue(..., .transformer = sprintf_transformer, .envir = .envir)
}


glue_fmt("π = {pi:.3f}")
# π = 3.142


## safely transformer ----

# A transformer that acts like `purrr::safely()`, which returns a value instead
# of an error.
safely_transformer <- function(otherwise = NA) {
  function(text, envir) {
    tryCatch(
      expr = eval(parse(text = text, keep.source = FALSE), envir),
      error = function(e) if (is.language(otherwise)) eval(otherwise) else otherwise
    )
  }
}


glue_safely <- function(..., .otherwise = NA, .envir = parent.frame()) {
  glue::glue(..., .transformer = safely_transformer(.otherwise), .envir = .envir)
}


# Default returns missing if there is an error
glue_safely("foo: {xyz}")
# foo: NA


# Or an empty string
glue_safely("foo: {xyz}", .otherwise = "Error")
# foo: Error


# Or output the error message in red
library(crayon)
glue_safely("foo: {xyz}", .otherwise = quote(glue::glue("{red}Error: {conditionMessage(e)}{reset}")))
# foo: Error: Object 'xyz' not found



## "Variables and Values" transformer ----


# A transformer that expands input of the form `{var_name=}` into `var_name = var_value`,
# i.e. a shorthand for exposing variable names with their values.

# This is inspired by an f-strings feature coming in Python 3.8.

# It is actually more general: You can use it with an expression input such as
# `{expr=}`.
vv_transformer <- function(text, envir) {
  regex <- "=$"
  if (!grepl(regex, text)) {
    return(glue::identity_transformer(text = text, envir = envir))
  }
  
  text <- sub(pattern = regex, replacement = "", x = text)
  res <- glue::identity_transformer(text = text, envir = envir)
  n <- length(res)
  res <- glue::glue_collapse(res, sep = ", ")
  if (n > 1) {
    res <- c("[", res, "]")
  }
  glue::glue_collapse(c(text, " = ", res))
}


set.seed(1234)
description <- "some random"
numbers <- sample(x = 100, size = 4)
average <- mean(numbers)
sum <- sum(numbers)

glue::glue("For {description} {numbers=}, {average=}, {sum=}", .transformer = vv_transformer)
# For some random numbers = [28, 80, 22, 9], average = 34.75, sum = 139

a <- 3
b <- 5.6
glue::glue("{a=}\n{b=}\n{a * 9 + b * 2=}", .transformer = vv_transformer)
# a = 3
# b = 5.6
# a * 9 + b * 2 = 38.2

# END