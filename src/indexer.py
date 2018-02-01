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
from itertools import islice, chain


# https://stackoverflow.com/a/24527424/4944625
def chunks(iterable, size=10):
    iterator = iter(iterable)
    for first in iterator:
        yield chain([first], islice(iterator, size - 1))


ONE_DAY = 24 * 3600 * 1000

s3 = boto3.resource('s3')
raw_html_bucket = s3.Bucket(os.environ['RAW_BUCKET'])

dynamodb = boto3.resource('dynamodb')
last_crawled_table = dynamodb.Table(os.environ['LAST_CRAWLED_TABLE'])

sns = boto3.resource('sns')
to_crawl_topic = sns.Topic(os.environ['SNS_TOPIC'])


def get_now_utc():
    return int(datetime.now(tz=timezone.utc).timestamp() * 1000)


def get_url_hash(url):
    return hashlib.sha256(url.encode('utf-8')).hexdigest()


def upload_to_s3(url_hash, html):
    file_obj = io.BytesIO(html.encode('utf-8'))
    raw_html_bucket.upload_fileobj(file_obj, '{}.html'.format(url_hash))


def handler(event, context):
    is_lambda_proxy = False
    records = event.get('Records')
    if event.get('httpMethod') == "POST":
        body = json.loads(event['body'])
        is_lambda_proxy = True
    elif records and 'Sns' in records[0]:
        body = json.loads(records[0]['Sns']['Message'])
    else:
        body = event
    url = body['url']
    url_filter = body['url_filter']
    depth_left = body.get('depth_left', 0)
    r = requests.get(url)
    url_hash = get_url_hash(url)
    html = r.text
    upload_to_s3(url_hash, html)
    last_crawled_table.put_item(Item={
        'url_hash': url_hash,
        'last_crawled': get_now_utc()
    })
    if depth_left > 0:
        soup = BeautifulSoup(html, 'html.parser')
        exp = re.compile(url_filter)
        links = list(
            u for u in set(
                urljoin(url, a.get('href')) for a in soup.find_all('a'))
            if exp.match(u))

        should_crawl = []
        for chunk in chunks(links):
            urls_in_chunk = list(chunk)
            response = dynamodb.batch_get_item(
                RequestItems={
                    os.environ['LAST_CRAWLED_TABLE']: {
                        'Keys': [{
                            'url_hash': get_url_hash(url)
                        } for url in urls_in_chunk],
                        'ConsistentRead':
                        False
                    }
                })
            last_crawled = {
                obj['url_hash']: int(obj['last_crawled'])
                for obj in response['Responses'][os.environ[
                    'LAST_CRAWLED_TABLE']]
            }
            for url in urls_in_chunk:
                url_hash = get_url_hash(url)
                if url_hash not in last_crawled or last_crawled[url_hash] <= get_now_utc(
                ) - ONE_DAY:
                    should_crawl.append(url)
        for url in should_crawl:
            to_crawl_topic.publish(
                Message=json.dumps({
                    'url': url,
                    'url_filter': url_filter,
                    'depth_left': depth_left - 1
                }))
        ret = {'success': True, 'new_crawled': len(should_crawl)}
    else:
        ret = {'success': True}
    if is_lambda_proxy:
        return {'statusCode': 200, 'body': json.dumps(ret)}
    return ret
    # raise Exception('Something went wrong')
