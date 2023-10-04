# Overview -----

# Glue offers interpreted string literals that are small, fast, and dependency-free.
# Glue does this by embedding R expressions in curly braces which are
# then evaluated and inserted into the argument string.


## Installation ----
library(tidyverse)
library(glue)

## Usage ----

### Variables can be passed directly into strings ----
name <- "Fred"
glue::glue("My name is {name}.")
# My name is Fred.

# Note that `glue::glue()` is also made available via
# `stringr::str_glue()`.
# So if you hav ealready loaded `stringr`, you can use `str_glue()`.
stringr_fcn <- "`stringr::str_glue()`"
glue_fcn <- "`glue::glue()`"

stringr::str_glue("{stringr_fcn} is essentially an alias for {glue_fcn}")
# `stringr::str_glue()` is essentially an alias for `glue::glue()`

# Check the source code to see that `stringr::str_glue()` is a wrapper around `glue::glue()`:
stringr::str_glue
# function(..., .sep = "", .envir = parent.frame()) {
#     glue::glue(..., sep = .sep, .envir = .envir)
# }


### Long strings are broken by line and concatenated together ----
name <- "Fred"
age <- 50
anniversary <- as.Date("1991-10-12")
glue::glue('My name is {name},',
           ' my age next year is {age + 1},',
           ' my anniversary is {format(anniversary, "%A, %B %d, %Y")}.')
# My name is Fred, my age next year is 51, my anniversary is Samstag, Oktober 12, 1991.


### Named arguments are used to assign temporary variables ----
glue::glue('My name is {name}',
           ' my age next year is {age + 1},',
           ' my anniversary is {format(anniversary, "%A, %B %d, %Y")}.',
           name = "Joe",
           age = 40,
           anniversary = as.Date("2001-10-12"))
# My name is Joe my age next year is 41, my anniversary is Freitag, Oktober 12, 2001.


### `glue::glue_data()` is useful with `magrittr` pipes ----
head(mtcars) %>% 
  glue::glue_data("{rownames(.)} has {hp} hp")
# Note that you can only use placeholders (.) with the `magrittr` pipe `%>%` but not
# with the native `base` pipe `|>`.  


### Or within `dplyr` pipelines -----
head(iris) %>%
  mutate(
    description = glue::glue("This {Species} has a petal length of {Petal.Length}")
  )



### Leading whitespace and blank lines from the first and last lines are automatically trimmed ----

# This lets you indent the strings naturally in code.
glue::glue("
     A formatted string
     Can have multiple lines
        with additional indention preserved
     ")
# A formatted string
# Can have multiple lines
#   with additional indention preserved


### An additional newline can be used if you want a leading or trailing newline ----
glue::glue("
     
     leading or trailing newlines can be added explicitly
     
     ")
# 
# leading or trailing newlines can be added explicitly
# 


### `\\` at the end of a line continues it without a new line ----
glue::glue("
     A formatted string \\
     can also be on a \\
     single line
     ")
# A formatted string can also be on a single line


### A literal brace is inserted by using double braces ----
name <- "Fred"
glue::glue("My name is {name}, not {{name}}.")
# My name is Fred, not {name}.


### Alternative delimiters can be specified with `.open` and `.close` ----
one <- "1"
glue::glue("The value of $e^{2\\pi i}$ is $<<one>>$.", 
     .open = "<<", 
     .close = ">>")
# The value of $e^{2\pi i}$ is $1$.


### All valid R code works in expressions, including braces and escaping ----

# Backslashes do need to be doubled just like in all R strings
`foo}\`` <- "foo"
glue::glue("{
      {
        '}\\'' # { and } in comments, single quotes
        \"}\\\"\" # or double quotes are ignored
        `foo}\\`` # as are { in backticks
      }
  }")
# foo


### `glue::glue_sql()` makes constructing SQL statements safe and easy ----

# Use back ticks to quote identifiers, normal strings and
# numbers are quoted appropriately for your backend.
con <- DBI::dbConnect(drv = RSQLite::SQLite(), ":memory:")

colnames(iris) <- gsub(pattern = "[.]", replacement = "_", x = tolower(colnames(iris)))

DBI::dbWriteTable(conn = con, name = "iris", value = iris)

var <- "sepal_width"
tbl <- "iris"
num <- 2
val <- "setosa"

glue::glue_sql("
         SELECT {`var`}
         FROM {`tbl`}
         WHERE {`tbl`}.sepal_length > {num}
           AND {`tbl`}.species = {val}
         ", .con = con)
# <SQL> SELECT `sepal_width`
# FROM `iris`
# WHERE `iris`.sepal_length > 2
# AND `iris`.species = 'setosa'


# `glue::glue_sql()` can be used in conjunction with parameterized queries in
# `DBI::dbBind()` to provide protection for SQL Injection attacks.
sql <- glue::glue_sql("
                SELECT {`var`}
                FROM {`tbl`}
                WHERE {`tbl`}.sepal_length > ?
                ", .con = con)

query <- DBI::dbSendQuery(conn = con, statement = sql)

DBI::dbBind(res = query, params = list(num))

DBI::dbFetch(res = query, n = 4)
#   sepal_width
# 1         3.5
# 2         3.0
# 3         3.2
# 4         3.1
DBI::dbClearResult(res = query)


#`glue::glue_sql()` can be used to build up more complex queries with
# interchangeable sub queries.
# It returns `DBI::SQL()` objects which are properly protected from quoting.
sub_query <- glue::glue_sql("
                            SELECT *
                            FROM {`tbl`}
                            ", .con = con)

glue::glue_sql("
               SELECT s.{`var`}
               FROM ({sub_query}) AS s
               ", .con = con)
# <SQL> SELECT s.`sepal_width`
# FROM (SELECT *
# FROM `iris`) AS s


# If you want to input multiple values for use in SQL IN statements put `*`
# at the end of the value and the values will be collapsed and quoted automatically.
glue::glue_sql("SELECT * FROM {`tbl`} WHERE sepal_length IN ({vals*})", 
               vals = 1, .con = con)
# <SQL> SELECT * FROM `iris` WHERE sepal_length IN (1)


glue::glue_sql("SELECT * FROM {`tbl`} WHERE sepal_length IN ({vals*})",
               vals = 1:5, .con = con)
# <SQL> SELECT * FROM `iris` WHERE sepal_length IN (1, 2, 3, 4, 5)


glue::glue_sql("SELECT * FROM {`tbl`} WHERE species in ({vals*})",
               vals = "setosa", .con = con)
# <SQL> SELECT * FROM `iris` WHERE species in ('setosa')


glue::glue_sql("SELECT * FROM {`tbl`} WHERE species IN ({vals*})",
               vals = c("setosa", "versicolor"), .con = con)
# <SQL> SELECT * FROM `iris` WHERE species IN ('setosa', 'versicolor')



### Optionally combine strings with `+` ----
x <- 1
y <- 3
glue::glue("x + y") + " = {x + y}"
# x + y = 4

# END