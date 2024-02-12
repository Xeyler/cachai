#!/bin/sh

DOCUMENTS_DIR="documents"
OUTPUT_DIR="out"

TEMP_DIR="$(mktemp --directory)"

# Get a JSON representation of the documents' file structure
tree -J --noreport "$DOCUMENTS_DIR" | jq \
'def trans:
  reduce .[] as $item ({}; 
    if $item.type == "directory" then 
      . + {($item.name): ($item.contents | trans)}
    else
      . + {($item.name | scan("^[^.]+")): 
      {"is_file": true, "extension": $item.name | scan("^[^.]+(.+)$") | .[0]}}
    end
  );
trans' > "$TEMP_DIR/documents.json"

# Do a first pass, processing front matter
find "$DOCUMENTS_DIR" -type f -name '*.md' | while read -r document;
do
    relative_url=$(echo "$document" | sed "s#$DOCUMENTS_DIR##" \
            | sed 's#.md$#.html#')
    doc_out=$(echo "$document" | sed "s#$DOCUMENTS_DIR#$TEMP_DIR#")
    mkdir --parents "$(dirname "$doc_out")"
    cp "$document" "$doc_out"

    # If the first line is three hyphens, process and strip the front matter
    # and add it to the jinja context
    if head -n 1 "$document" | grep --silent '^---$'; then
        yq --front-matter=extract --input-format yaml --output-format json \
                ".url=\"$relative_url\"" "$document" > "$doc_out.json"
        sed --in-place '1{/^---$/!q;};1,/^---$/d' "$doc_out"
        json_selector=$(echo "$document" | grep -oE "^.+/[^.]+" | sed "s#/#.#g")
        jq -s ".[0].$json_selector += .[1] | .[0]" "$TEMP_DIR/documents.json" \
        "$doc_out.json" > "$TEMP_DIR/documents.json.new"
        mv "$TEMP_DIR/documents.json.new" "$TEMP_DIR/documents.json"
    fi
done

# Do a second pass, rendering files with jinja
find "$TEMP_DIR" -type f -name '*.md' | while read -r document;
do
    part=$(echo "$document" | sed 's#.md$#.html#')
    doc_out=$(echo "$part" | sed "s#$TEMP_DIR#$OUTPUT_DIR#")
    mkdir --parents "$(dirname "$doc_out")"

    placeholders=$(mktemp)
    sed 's/{[{%#][^}%#]*[}%#]}/<!--JINJA-PLACEHOLDER-->/g' < "$document" > "$placeholders"

    cat "$placeholders"
    
    kramdown --no-html-to-native "$document" > "$part"
    if [ -e "$document.json" ]; then
        jq -s '.[0] * .[1]' "$TEMP_DIR/documents.json" "$document.json" | \
        j2 --undefined --format=json "$part" -o "$doc_out"
    else
        j2 --undefined --format=json "$part" -o "$doc_out" < "$TEMP_DIR/documents.json"
    fi
done