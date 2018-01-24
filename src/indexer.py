from bs4 import BeautifulSoup
import requests
from urllib.parse import urljoin
import boto3

def handler(event, context):
    # print("Received event: " + json.dumps(event, indent=2))
    url = event['url']
    r = requests.get(url)
    html = r.text
    soup = BeautifulSoup(html, 'html.parser')
    links = set(urljoin(url, a.get('href')) for a in soup.find_all('a'))
    return {'success': True}
    # raise Exception('Something went wrong')
