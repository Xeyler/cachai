#!/bin/sh

DOCUMENTS_DIR="documents/"
OUTPUT_DIR="out/"

TEMP_DIR="$(mktemp --directory)/"

# Do a first pass, processing front matter
find "$DOCUMENTS_DIR" -type f -name '*.md' | while read -r document;
do
    relative_url=$(echo "$document" | sed "s#$DOCUMENTS_DIR##" \
            | sed 's#.md$#.html#')
    doc_out=$(echo "$document" | sed "s#$DOCUMENTS_DIR#$TEMP_DIR#")
    mkdir --parents "$(dirname "$doc_out")"
    cp "$document" "$doc_out"

    # If the first line is three hyphens, process and strip the front matter
    if head -n 1 "$document" | grep --silent '^---$'; then
        yq --front-matter=extract --input-format yaml --output-format json \
                ".url=\"$relative_url\"" "$document" > "$doc_out.json"
        sed --in-place '1{/^---$/!q;};1,/^---$/d' "$doc_out"
    fi
done

# Do a second pass, rendering files with jinja
find "$TEMP_DIR" -type f -name '*.md' | while read -r document;
do
    part=$(echo "$document" | sed 's#.md$#.html#')
    doc_out=$(echo "$part" | sed "s#$TEMP_DIR#$OUTPUT_DIR#")
    mkdir --parents "$(dirname "$doc_out")"
    # TODO: Make jinja and the markdown converter play nice
    # TODO: aggregate all json files and directory tree into context
    # (this will make this conditional unnecessary)
    if [ -e "$document.json" ]; then
        j2 "$document" "$document.json" -o "$part"
    else
        j2 "$document" -o "$part"
    fi
    kramdown --no-html-to-native "$part" > "$doc_out"
done