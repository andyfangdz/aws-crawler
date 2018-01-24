from bs4 import BeautifulSoup
import requests
from urllib.parse import urljoin
import boto3
import json

def handler(event, context):
    is_lambda_proxy = False
    if event.get('httpMethod') == "POST":
        body = json.loads(event['body'])
        url = body['url']
        is_lambda_proxy = True
    else:
        url = event['url']
    r = requests.get(url)
    html = r.text
    soup = BeautifulSoup(html, 'html.parser')
    links = set(urljoin(url, a.get('href')) for a in soup.find_all('a'))

    ret = {'success': True, 'urls': list(links)}
    if is_lambda_proxy:
        return {
            'statusCode':200,
            'body': json.dumps(ret)
        }
    return ret
    # raise Exception('Something went wrong')
