# Script to generate PNG version of the logo from SVG
#
# This script requires either:
# - rsvg package (recommended for high quality SVG to PNG conversion)
# - OR magick package (alternative)
#
# Run this script after modifying the SVG logo to regenerate the PNG

library(here)

# Paths
svg_path <- here::here("man", "figures", "logo.svg")
png_path <- here::here("man", "figures", "logo.png")

# Check which package is available
if (requireNamespace("rsvg", quietly = TRUE)) {
  message("Using rsvg to convert SVG to PNG...")
  rsvg::rsvg_png(svg_path, png_path, width = 240)
  message("PNG logo created at: ", png_path)
} else if (requireNamespace("magick", quietly = TRUE)) {
  message("Using magick to convert SVG to PNG...")
  img <- magick::image_read_svg(svg_path, width = 240)
  magick::image_write(img, png_path, format = "png")
  message("PNG logo created at: ", png_path)
} else {
  stop(
    "Please install either 'rsvg' or 'magick' package to convert SVG to PNG:\n",
    "  install.packages('rsvg')   # Recommended\n",
    "  # OR\n",
    "  install.packages('magick')"
  )
}

message("\nTo use the logo in README.md, add:\n")
message('# foundryR <img src="man/figures/logo.png" align="right" height="139" alt="" />')
