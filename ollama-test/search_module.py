import requests
import json

def search_serpapi(query, api_key):
    url = "https://serpapi.com/search"
    params = {
        'q': query,
        'engine': 'google',
        'api_key': api_key
    }
    
    try:
        response = requests.get(url, params=params)
        response.raise_for_status()  # Raise an exception for HTTP errors
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"An error occurred: {e}")
        return None

if __name__ == "__main__":
    with open(".env", "r") as env_file:
        env = json.load(env_file)
    
    serpapi_api_key = env.get("SERPAPI_API_KEY")
    search_query = "Python programming language"
    
    if not serpapi_api_key:
        print("SERPAPI API key not found in .env file.")
    else:
        results = search_serpapi(search_query, serpapi_api_key)
        
        # Save the results to a JSON file or use them as needed
        if results:
            with open("search_results.json", "w") as f:
                json.dump(results, f, indent=4)
            print("Search results saved to 'search_results.json'")
        else:
            print("Failed to retrieve search results.")