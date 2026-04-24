#!/bin/bash

# Set the directory where the Python script and environment variables are located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables from .env file
source "$SCRIPT_DIR/.env"

# Check if SERPAPI_API_KEY is set in the .env file
if [[ -z "$SERPAPI_API_KEY" ]]; then
  echo "Error: SERPAPI_API_KEY is not set in the .env file."
  exit 1
fi

# Run the Python script with the API key and search query
python3 "$SCRIPT_DIR/search_module.py"

echo "Search completed. Results saved to 'search_results.json'"