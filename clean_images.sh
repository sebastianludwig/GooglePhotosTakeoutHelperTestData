#!/bin/bash
set -e

usage () {
    echo "Converts each image into an empty, white image while preserving the"
    echo "EXIF data (except the preview thumbnail)."
    echo "Requires 'convert' (ImageMagick) and 'exiftool' to be installed."
    echo ""
    echo "Usage: clean_images.sh <folder>"
}

abort () {
    echo "Error: $1." >&2
    exit 1
}

if [[ $1 == "-h" || $1 == "--help" ]]; then
    usage
    exit 0
fi

if [[ "$#" -ne 1 ]]; then
    abort "Illegal number of arguments"
fi

if ! [[ -x "$(command -v convert)" ]]; then
    abort "convert (ImageMagick) is not installed"
fi

if ! [[ -x "$(command -v exiftool)" ]]; then
    abort "exiftool is not installed"
fi

input_directory="$1"
output_directory="$input_directory/cleaned"

mkdir -p "$output_directory"

for file_path in "$input_directory"/*; do
    filename=$(basename -- "$file_path")
    extension=$(echo "${filename##*.}" | tr '[:upper:]' '[:lower:]') # converted to lowercase

    if [[ $extension == "jpg" ||  $extension == "jpeg" || $extension == "png" ]]; then
        convert -size 8x8 xc:white "$output_directory/$filename"
        convert "$file_path" "$output_directory/$filename" -resize 8x8! -composite "$output_directory/$filename"
        # remove the thumbnail image to not leak the image contents there
        exiftool -ThumbnailImage= -overwrite_original_in_place -quiet "$output_directory/$filename"
        # restore original file dates
        touch -r "$file_path" "$output_directory/$filename"
        mv "$output_directory/$filename" "$file_path"
    fi
done

rm -r "$output_directory"
