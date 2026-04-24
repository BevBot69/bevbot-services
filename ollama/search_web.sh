#!/bin/bash

# Function to search the web using DuckDuckGo
search_web() {
    query="$1"
    api_key="YOUR_DUCKDUCKGO_API_KEY"

    # Construct the URL with the search query
    url="https://api.duckduckgo.com/?q=$query&format=json&pretty=1&key=$api_key"

    # Make the HTTP request and capture the response
    response=$(curl -s "$url")

    # Print or process the response as needed
    echo "$response"
}

# Example usage
search_query="$@"
search_web "$search_query"