# Speed of glue ----

# Glue is advertised as
#   Fast, dependency free string literals.

# We can compare `glue` to some alternatives such as:

# - `base::paste0()`, `base::sprintf()` - Functions in `base` R implemented in `C`
#   that provide variable insertion (but not interpolation).

# - `R.utils::gstring()`, `stringr::str_interp()` - Provides a similar interface
#   as `glue`, but using `${}` to delimit blocks to interpolate.

# - `pystr::pystr_format()`, `rprintf::rprintf()` - Provide interfaces similar to 
#   `Python` string formatters with variable replacement, but not arbitrary interpolation.


## Simple concatenation ----
bar <- "baz"

simple <- microbenchmark::microbenchmark(
  glue       = glue::glue("foo{bar}"),
  gstring    = R.utils::gstring("foo${bar}"),
  paste0     = paste0("foo", bar),
  sprintf    = sprintf("foo%s", bar),
  str_interp = stringr::str_interp("foo${bar}"),
  rprintf    = rprintf::rprintf("foo$bar", bar = bar)
)

print(unit = "eps", order = "median", signif = 4, simple)

plot(simple)
dev.off()

# `glue::glue()` is not the fastest function for simple concatenation,
# but it is similar in speed to the `base::paste0()` and `base::sprintf()` functions.


## Vectorized performance ----

# Taking advantage of `glue`'s vectorization is the best way to improve performance.

# The vectorized form of the previous benchmark is able to generate 100,000
# strings in only 22 miliseconds with performance much closer to that of
# `base::paste0()` and `base::sprintf()`.

# `str_interp()` is not included as it does not support vectorization.

bar <- rep(x = "bar", times = 1e5)

vectorized <- microbenchmark::microbenchmark(
  glue    = glue::glue("foo{bar}"),
  gstring = R.utils::gstring("foo${bar}"),
  paste0  = paste0("foo", bar),
  sprintf = sprintf("foo5%s", bar),
  rprintf = rprintf::rprintf("foo$bar", bar = bar)
)


print(unit = "ms", order = "median", signif = 4, vectorized)

plot(vectorized)
dev.off()

# END