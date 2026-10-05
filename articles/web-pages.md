# Comparing web pages and htmlwidgets

odiffr compares images; it does not open web pages or drive a browser.
To test how a web page, an R Markdown/Quarto report or an htmlwidget
looks, take a screenshot with a headless browser first, for example with
[webshot2](https://rstudio.github.io/webshot2/) or
[chromote](https://rstudio.github.io/chromote/) (both use Chrome or
Chromium), and then compare the PNG files with odiff. For Shiny apps,
see
[`vignette("shinytest2")`](https://benwolst.github.io/odiffr/articles/shinytest2.md).

## Screenshot a page

``` r

webshot2::webshot(
  "https://example.com",
  file = "current/home.png",
  vwidth = 1280, vheight = 800,
  delay = 0.5           # let the page settle
)
```

Local HTML files work too, e.g. a rendered report:
`webshot2::webshot("report.html", "current/report.png")`.

## Screenshot an htmlwidget

Save the widget as an HTML file, then take a screenshot of it:

``` r

widget <- DT::datatable(head(iris))  # any htmlwidget

html <- tempfile(fileext = ".html")
htmlwidgets::saveWidget(widget, html, selfcontained = TRUE)
webshot2::webshot(html, file = "current/table.png",
                  vwidth = 800, vheight = 600, delay = 1)
```

Keep everything deterministic that you can: a fixed viewport size, a
fixed zoom level, a fixed seed for random data, and no animations (many
widgets have an option to disable them). Map tiles and other content
loaded from the internet can change at any time; avoid them in tests or
hide them with `ignore_regions`.

## Compare with a baseline

Browser screenshots contain anti-aliasing noise around rounded corners,
borders and text. The `"screenshot"` preset ignores anti-aliased pixels
while keeping the colour threshold low (see
[`?odiff_preset`](https://benwolst.github.io/odiffr/reference/odiff_preset.md)):

``` r

library(odiffr)

result <- do.call(compare_images, c(
  list("baseline/home.png", "current/home.png", diff_output = "home-diff.png"),
  odiff_preset("screenshot")
))
result$match
```

For many pages at once, use
[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)
and
[`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md):

``` r

results <- do.call(compare_image_dirs, c(
  list("baseline/", "current/", diff_dir = "diffs/"),
  odiff_preset("screenshot")
))
batch_report(results, output_file = "report.html", images = "all",
             embed = TRUE)
```

## As a testthat snapshot

[`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md)
stores the screenshot as a testthat snapshot and compares it with odiff
on later runs. On failure a diff image is written to
`tests/testthat/_odiffr/`.

``` r

test_that("report looks the same", {
  skip_if_not_installed("webshot2")
  path <- tempfile(fileext = ".png")
  webshot2::webshot("report.html", file = path,
                    vwidth = 1024, vheight = 768)

  expect_snapshot_image(
    path,
    name = "report",
    preset = "screenshot",
    variant = Sys.info()[["sysname"]]  # fonts differ between systems
  )
})
```

Review changes with
[`testthat::snapshot_review()`](https://testthat.r-lib.org/reference/snapshot_accept.html),
and on CI write a report of all changed snapshots with
[`snapshot_report()`](https://benwolst.github.io/odiffr/reference/snapshot_report.md).
