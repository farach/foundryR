# Generate the foundryR hex sticker and pkgdown favicons.
#
# Design: an indigo gradient hexagon in Microsoft Foundry's icon palette
# (#7274FF, #4F42FD, #2C08AC) with an original three-face ingot mark -- a
# foundry's cast output -- above a "foundryR" wordmark. The wordmark uses
# Selawik Semibold, Microsoft's open-source Segoe UI-style font (SIL Open Font
# License 1.1), converted to outlines so the SVG renders identically everywhere.
# Small favicons use the mark without the wordmark.
#
# The ingot and the wordmark are centered on their measured ink bounds, not on
# nominal font metrics, so the ingot's visible side face does not pull the mark
# off center.
#
# Requires: systemfonts, textshaping, rsvg, magick, jsonlite.
# Run from the package root: source("data-raw/create_logo.R")

indigo_light <- "#7274FF"
indigo <- "#4F42FD"
indigo_deep <- "#2C08AC"
ingot_fills <- c(top = "#FFFFFF", front = "#E2E0FF", side = "#B7B3FF")

hex_center <- c(260, 300)
optical_center_y <- 296

font_path <- file.path(tempdir(), "selawik", "selawksb.ttf")
if (!file.exists(font_path)) {
  font_zip <- tempfile(fileext = ".zip")
  utils::download.file(
    "https://github.com/microsoft/Selawik/releases/download/1.01/Selawik_Release.zip",
    font_zip,
    mode = "wb"
  )
  utils::unzip(font_zip, exdir = dirname(font_path))
}
stopifnot(file.exists(font_path))

fmt <- function(x) {
  formatC(round(x, 2), format = "f", digits = 2, drop0trailing = TRUE)
}

rounded_polygon <- function(x, y, radius) {
  n <- length(x)
  parts <- character(n)
  for (i in seq_len(n)) {
    previous <- if (i == 1) n else i - 1
    following <- if (i == n) 1 else i + 1
    incoming <- c(x[previous] - x[i], y[previous] - y[i])
    outgoing <- c(x[following] - x[i], y[following] - y[i])
    r <- min(radius, sqrt(sum(incoming^2)) / 2, sqrt(sum(outgoing^2)) / 2)
    start <- c(x[i], y[i]) + incoming / sqrt(sum(incoming^2)) * r
    end <- c(x[i], y[i]) + outgoing / sqrt(sum(outgoing^2)) * r
    parts[i] <- sprintf(
      "%s%s %s Q%s %s %s %s",
      if (i == 1) "M" else "L",
      fmt(start[1]),
      fmt(start[2]),
      fmt(x[i]),
      fmt(y[i]),
      fmt(end[1]),
      fmt(end[2])
    )
  }
  paste(c(parts, "Z"), collapse = " ")
}

hex_path <- function(radius = 290, corner = 26) {
  angles <- seq(-90, 210, by = 60) * pi / 180
  rounded_polygon(
    hex_center[1] + radius * cos(angles),
    hex_center[2] + radius * sin(angles),
    corner
  )
}

# Ingot faces in a local coordinate system. The top face sits above a wider
# base, and the right side face is visible, as seen from the front and above.
ingot_faces <- function() {
  top_left <- c(-47, -10)
  top_right <- c(51, -10)
  base_left <- c(-80, 44)
  base_right <- c(70, 44)
  back_top_right <- top_right + c(22, -20)
  back_top_left <- top_left + c(22, -20)
  back_base_right <- base_right + c(34, -30)
  list(
    silhouette = list(
      base_left,
      top_left,
      back_top_left,
      back_top_right,
      back_base_right,
      base_right
    ),
    side = list(top_right, back_top_right, back_base_right, base_right),
    front = list(top_left, top_right, base_right, base_left),
    top = list(top_left, back_top_left, back_top_right, top_right)
  )
}

ingot_bounds <- function(scale) {
  points <- do.call(rbind, ingot_faces()$silhouette) * scale
  c(
    xmin = min(points[, 1]),
    xmax = max(points[, 1]),
    ymin = min(points[, 2]),
    ymax = max(points[, 2])
  )
}

# Draws the ingot so that its silhouette's bounding box is centered on
# (center_x, center_y). Faces are drawn with sharp shared edges over a side-color
# underlay, then clipped to one rounded silhouette, so outer corners are soft and
# face joins stay crisp.
ingot_svg <- function(center_x, center_y, scale, id) {
  bounds <- ingot_bounds(scale)
  dx <- center_x - (bounds[["xmin"]] + bounds[["xmax"]]) / 2
  dy <- center_y - (bounds[["ymin"]] + bounds[["ymax"]]) / 2
  face_path <- function(points, corner = 0) {
    coords <- do.call(rbind, points) * scale
    rounded_polygon(coords[, 1] + dx, coords[, 2] + dy, corner)
  }
  faces <- ingot_faces()
  clip_id <- paste0("foundryr-ingot-", id)
  paste(
    sprintf(
      '<clipPath id="%s"><path d="%s"/></clipPath>',
      clip_id,
      face_path(faces$silhouette, 6 * scale)
    ),
    sprintf('<g clip-path="url(#%s)">', clip_id),
    sprintf(
      '  <path d="%s" fill="%s"/>',
      face_path(faces$silhouette),
      ingot_fills[["side"]]
    ),
    sprintf(
      '  <path d="%s" fill="%s"/>',
      face_path(faces$front),
      ingot_fills[["front"]]
    ),
    sprintf(
      '  <path d="%s" fill="%s"/>',
      face_path(faces$top),
      ingot_fills[["top"]]
    ),
    '</g>',
    sep = "\n  "
  )
}

# Returns wordmark outlines in local coordinates (baseline at y = 0, y down).
wordmark_outlines <- function(text, size, tracking) {
  shaped <- textshaping::shape_text(text, path = font_path, size = size)[[
    "shape"
  ]]
  offsets <- shaped$x_offset + tracking * (seq_len(nrow(shaped)) - 1)
  contours <- list()
  for (i in seq_len(nrow(shaped))) {
    outline <- systemfonts::glyph_outline(
      shaped$index[i],
      path = font_path,
      size = size,
      tolerance = 0.08
    )
    for (contour in split(outline, outline$contour)) {
      contours[[length(contours) + 1]] <- cbind(
        offsets[i] + contour$x,
        -contour$y
      )
    }
  }
  contours
}

outline_path <- function(contours, dx, dy) {
  paste(
    vapply(
      contours,
      function(points) {
        x <- points[, 1] + dx
        y <- points[, 2] + dy
        paste0(
          "M",
          fmt(x[1]),
          " ",
          fmt(y[1]),
          " ",
          paste0("L", fmt(x[-1]), " ", fmt(y[-1]), collapse = " "),
          " Z"
        )
      },
      character(1)
    ),
    collapse = " "
  )
}

svg_document <- function(description, body) {
  paste0(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 520 600" width="520" height="600" ',
    'role="img" aria-labelledby="title desc">\n',
    '  <title id="title">foundryR</title>\n',
    '  <desc id="desc">',
    description,
    '</desc>\n',
    '  <defs>\n',
    '    <linearGradient id="foundryr-field" x1="0.15" y1="0" x2="0.85" y2="1">\n',
    '      <stop offset="0" stop-color="',
    indigo_light,
    '"/>\n',
    '      <stop offset="0.48" stop-color="',
    indigo,
    '"/>\n',
    '      <stop offset="1" stop-color="',
    indigo_deep,
    '"/>\n',
    '    </linearGradient>\n',
    '  </defs>\n',
    '  <path d="',
    hex_path(),
    '" fill="url(#foundryr-field)"/>\n',
    '  ',
    body,
    '\n',
    '</svg>'
  )
}

# Writes text with LF line endings on every platform.
write_lf <- function(text, path) {
  connection <- file(path, open = "wb")
  on.exit(close(connection))
  writeLines(text, connection, sep = "\n", useBytes = TRUE)
}

# Sticker: ingot above the wordmark, centered as one block.
ingot_scale <- 1.25
word_gap <- 50
word <- wordmark_outlines("foundryR", size = 70, tracking = 1.2)
word_points <- do.call(rbind, word)
word_bounds <- c(
  xmin = min(word_points[, 1]),
  xmax = max(word_points[, 1]),
  ymin = min(word_points[, 2]),
  ymax = max(word_points[, 2])
)
ingot_height <- diff(ingot_bounds(ingot_scale)[c("ymin", "ymax")])
word_height <- word_bounds[["ymax"]] - word_bounds[["ymin"]]
block_top <- optical_center_y - (ingot_height + word_gap + word_height) / 2
ingot_center_y <- block_top + ingot_height / 2
word_dx <- hex_center[1] - (word_bounds[["xmin"]] + word_bounds[["xmax"]]) / 2
word_dy <- block_top + ingot_height + word_gap - word_bounds[["ymin"]]

sticker <- svg_document(
  "foundryR hex sticker: a white ingot above the foundryR wordmark on an indigo gradient hexagon.",
  paste(
    ingot_svg(hex_center[1], ingot_center_y, ingot_scale, "sticker"),
    sprintf(
      '<path d="%s" fill="#FFFFFF"/>',
      outline_path(word, word_dx, word_dy)
    ),
    sep = "\n  "
  )
)
mark <- svg_document(
  "foundryR icon: a white ingot on an indigo gradient hexagon.",
  ingot_svg(hex_center[1], hex_center[2], 1.9, "icon")
)

logo_path <- file.path("man", "figures", "logo.svg")
favicon_dir <- file.path("pkgdown", "favicon")
write_lf(sticker, logo_path)
write_lf(mark, file.path(favicon_dir, "favicon.svg"))

# Raster favicons: the hexagon is centered on a transparent square canvas, except
# for the Apple touch icon, which iOS expects to be opaque.
mark_file <- file.path(favicon_dir, "favicon.svg")
render_mark <- function(size, fill_height = 1, background = "none") {
  hex_height <- round(size * fill_height)
  image <- magick::image_read(rsvg::rsvg_png(mark_file, height = hex_height))
  canvas <- magick::image_blank(size, size, background)
  magick::image_composite(canvas, image, operator = "over", gravity = "center")
}
write_png <- function(image, name) {
  magick::image_write(
    image,
    file.path(favicon_dir, name),
    format = "png",
    depth = 8
  )
}
write_png(render_mark(96), "favicon-96x96.png")
write_png(render_mark(192), "web-app-manifest-192x192.png")
write_png(render_mark(512), "web-app-manifest-512x512.png")
write_png(
  render_mark(180, fill_height = 0.86, background = "#FFFFFF"),
  "apple-touch-icon.png"
)
ico <- magick::image_join(lapply(c(48, 32, 16), render_mark))
magick::image_write(ico, file.path(favicon_dir, "favicon.ico"), format = "ico")

manifest <- list(
  name = "foundryR",
  short_name = "foundryR",
  icons = list(
    list(
      src = "/web-app-manifest-192x192.png",
      sizes = "192x192",
      type = "image/png",
      purpose = "any"
    ),
    list(
      src = "/web-app-manifest-512x512.png",
      sizes = "512x512",
      type = "image/png",
      purpose = "any"
    )
  ),
  theme_color = indigo,
  background_color = "#ffffff",
  display = "standalone"
)
write_lf(
  jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE),
  file.path(favicon_dir, "site.webmanifest")
)

message("Wrote ", logo_path, " and pkgdown favicons.")
