from bs4 import BeautifulSoup
import requests
from urllib.parse import urljoin
import boto3
import json
import os
import hashlib
import io
import re
from datetime import timezone, datetime

s3 = boto3.resource('s3')
raw_html_bucket = s3.Bucket(os.environ['RAW_BUCKET'])

dynamodb = boto3.resource('dynamodb')
last_crawled_table = dynamodb.Table(os.environ['LAST_CRAWLED_TABLE'])


def upload_to_s3(url_hash, html):
    file_obj = io.BytesIO(html.encode('utf-8'))
    raw_html_bucket.upload_fileobj(file_obj, '{}.html'.format(url_hash))


def handler(event, context):
    is_lambda_proxy = False
    if event.get('httpMethod') == "POST":
        body = json.loads(event['body'])
        is_lambda_proxy = True
    else:
        body = event
    url = body['url']
    url_filter = body['url_filter']
    r = requests.get(url)
    url_hash = hashlib.sha256(url.encode('utf-8')).hexdigest()
    html = r.text
    upload_to_s3(url_hash, html)
    last_crawled_table.put_item(
        Item={
            'url_hash': url_hash,
            'last_crawled': int(
                datetime.now(tz=timezone.utc).timestamp() * 1000)
        })
    soup = BeautifulSoup(html, 'html.parser')
    exp = re.compile(url_filter)
    links = list(
        u for u in set(
            urljoin(url, a.get('href')) for a in soup.find_all('a'))
        if exp.match(u))

    ret = {'success': True, 'urls': list(links)}
    if is_lambda_proxy:
        return {'statusCode': 200, 'body': json.dumps(ret)}
    return ret
    # raise Exception('Something went wrong')
