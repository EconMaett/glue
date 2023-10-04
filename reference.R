# Function reference ----
library(tidyverse)
library(glue)

## Construct strings with color ----

# The `crayon` package defines a number of functions used to color terminal output.

# `glue::glue_col()` and `glue::glue_data_col()` functions provide
# additional syntax to make using these functions in glue strings easier.

# Using the following syntax will apply the function `crayon::blue()`
# to the text "foo bar".
# `{blue foo bar}`

# If you want an expression to be evaluated, simply place that in normal
# brace expression (these can be nested).
# `{blue 1 + 1 = {1 + 1}}`

# If the text you want to color contains, e.g., an unpaired quote or 
# a comment character, specify `.literal = TRUE`.

### Usage

# `glue::glue_col(..., .envir = parent.frame(), .na = "NA", .literal = FALSE)`
# `glue::glue_data_col(..., .envir = parent.frame(), .na = "NA", .literal = FALSE)`

library(crayon)

glue::glue_col("{blue foo bar}")
# foo bar

glue::glue_col("{blue 1 + 1 = {1 + 1}}")
# 1 + 1 = 2

glue::glue_col("{blue 2 + 2 = {green {2 + 2}}}")
# 2 + 2 = 4

white_on_black <- bgBlack $ white
glue::glue_col("{white_on_black
               Roses are {red {colors()[[552]]}},
               Violets are {blue {colors()[[26]]}},
               `glue::glue_col()` can show \\
               {red c}{yellow o}{green l}{cyan o}{blue r}{magenta s}
               and {bold bold} and {underline underline} too!
               }")
# Roses are red,
# Violets are blue,
# `glue::glue_col()` can show colors
# and bold and underline too!


# this would error due to an unterminated quote, if we did not specify
# `.literal = TRUE`
glue::glue_col("{yellow It's} happening!", .literal = TRUE)
# It's happening!


# `.literal = TRUE` also prevents an error here due to the `#` comment
glue::glue_col(
  "A URL: {magenta https://github.com/tidyverse/glue#readme}",
  .literal = TRUE
)
# A URL: https://github.com/tidyverse/glue#readme


# `.literal = TRUE` does NOT prevent evaluation
x <- "world"
y <- "day"
glue::glue_col("hello {x}! {green it's a new {y}!}", .literal = TRUE)
# hello world! it's a new day!

# END