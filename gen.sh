#!/bin/bash

#==============================================================================
# Markdown to HTML Conversion Script
#==============================================================================
# Purpose: Convert notes.md to index.html with update timestamp
# Dependencies: pandoc (brew install pandoc)
#==============================================================================

set -e  # Exit immediately on error

# Constants
readonly SOURCE_FILE="notes.md"
readonly OUTPUT_FILE="index.html"
readonly STYLES_FILE="styles.css"

# Helper functions
print_info() { echo "📝 $1"; }
print_success() { echo "✅ $1"; }

# Get current date for update timestamp
get_current_date() {
    date '+%Y/%m/%d'
}

# Generate table of contents for h2 headings
generate_toc() {
    local html_content="$1"

    # Extract h2 headings and their IDs
    local toc_items
    toc_items=$(echo "$html_content" | grep -E '^<h2 id="[^"]*">' | sed -E 's|<h2 id="([^"]*)">([^<]*)</h2>|  <li><a href="#\1">\2</a></li>|')

    if [ -n "$toc_items" ]; then
        echo "<nav class=\"toc\">
  <h3>Index</h3>
  <ul><li><a href="#">Home</a></li></ul>
  <ul>
$toc_items
  </ul>
</nav>"
    fi
}

# Convert markdown to HTML and add update timestamp
convert_to_html() {
    local title="$1"
    local update_time="$2"

    # Convert markdown to HTML content
    local html_content
    html_content=$(pandoc "$SOURCE_FILE" --from markdown --to html --no-highlight --wrap=none)

    # Generate table of contents for h2 headings (before adding update time)
    local toc
    toc=$(generate_toc "$html_content")

    # Add update timestamp after H1 if exists, otherwise add title and timestamp
    if echo "$html_content" | grep -q "^<h1"; then
        # Insert update time after existing H1
        html_content=$(echo "$html_content" | awk -v update="$update_time" '
            /<\/h1>/ && !inserted {
                print $0
                print "<p>当然，我在扯淡。</p>"
                print "<p class=\"update-time\">Updated: " update "</p>"
                inserted = 1
                next
            }
            { print }
        ')
    else
        # Add title and update time at the beginning
        html_content="<h1>${title}</h1>
<p>当然，我在扯淡。</p>
<p class=\"update-time\">Updated: ${update_time}</p>
${html_content}"
    fi

    # Process footer styling - replace <center> tags with styled paragraphs
    html_content=$(echo "$html_content" | sed 's|<center>|<p class="footer-quote">|g')
    html_content=$(echo "$html_content" | sed 's|</center>|</p>|g')

    html_content=$(echo "$html_content" | perl -pe 's/<h3([^>]*)>/<h3\1> ♦ /g')

    # Return content only, TOC will be passed separately
    echo "$html_content"
}

# Generate complete HTML page
generate_html_page() {
    local title="$1"
    local content="$2"
    local toc="$3"

    cat << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
    <link rel="stylesheet" href="${STYLES_FILE}">
</head>
<body>
<div class="container">
    <div class="main-content">
${content}
    </div>
    <div class="sidebar">
${toc}
    </div>
</div>
</body>
</html>
EOF
}

# Main function
main() {
    print_info "Converting $SOURCE_FILE to $OUTPUT_FILE..."

    # Check dependencies and files
    if ! command -v pandoc >/dev/null 2>&1; then
        echo "❌ Error: pandoc is required (brew install pandoc)"
        exit 1
    fi

    if [ ! -f "$SOURCE_FILE" ]; then
        echo "❌ Error: $SOURCE_FILE not found"
        exit 1
    fi

    if [ ! -f "$STYLES_FILE" ]; then
        echo "❌ Error: $STYLES_FILE not found"
        exit 1
    fi

    # Extract title and get current date
    local title
    title="Aha, I'm Just Kidding."
    local update_time
    update_time=$(get_current_date)

    print_info "Title: $title"
    print_info "Update time: $update_time"

    # Convert markdown to HTML
    local html_content
    html_content=$(convert_to_html "$title" "$update_time")

    # Generate TOC from the HTML content
    local toc
    toc=$(generate_toc "$html_content")

    # Generate complete HTML page
    local full_html
    full_html=$(generate_html_page "$title" "$html_content" "$toc")

    # Save to file
    echo "$full_html" > "$OUTPUT_FILE"

    print_success "Generated $OUTPUT_FILE successfully!"
}

# Run main function
main "$@"
