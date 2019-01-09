#!/usr/bin/env python3
import os
import boto3
import base64
import logging

from botocore.vendored import requests
from datetime import datetime
from dateutil import tz

ENCRYPTED_HOOK_URL = os.getenv("MATTERMOST_WEBHOOK_URL")
MATTERMOST_CHANNEL = os.getenv("MATTERMOST_CHANNEL")
MATTERMOST_USERNAME = os.getenv("MATTERMOST_USERNAME")
MATTERMOST_ICONURL = os.getenv("MATTERMOST_ICONURL")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def decrypt(encrypted_url):
    region = os.getenv("AWS_REGION")
    try:
        kms = boto3.client('kms', region_name=region)
        plaintext = kms.decrypt(CiphertextBlob=base64.b64decode(encrypted_url))[
            'Plaintext'].decode('utf-8')
        return plaintext
    except Exception:
        logger.exception("Failed to decrypt URL")


def format_date(date):
    from_zone = tz.gettz("UTC")
    to_zone = tz.gettz("America/Chicago")
    try:
        return datetime.strptime(date, "%Y-%m-%dT%H:%M:%SZ") \
            .replace(tzinfo=from_zone) \
            .astimezone(to_zone) \
            .strftime("%a %b %d, %Y at %I:%M:%S%Z %p")
    except Exception:
        logger.exception("Failed to parse datetime")


def notify_mattermost(message):
    if not ENCRYPTED_HOOK_URL.startswith("https:"):
        mattermost_url = decrypt(ENCRYPTED_HOOK_URL)
    else:
        mattermost_url = ENCRYPTED_HOOK_URL

    aws_url = "https://console.aws.amazon.com/ec2/v2/home?region={}#Images:sort=name"

    payload = {
        "channel": MATTERMOST_CHANNEL,
        "username": MATTERMOST_USERNAME,
        "icon_url": MATTERMOST_ICONURL,
        "attachments": [
            {
                'fallback': message.get('detail-type'),
                'color': '#759C3D',
                'text': 'New AMI created in [{0}]({1})!'.format(message.get("region"), aws_url.format(message.get("region"))),
                'title': message.get('detail-type'),
                'title_link': 'https://gihub.com/artur-sak13/unops',
                'fields': [
                    {
                        "short": True,
                        "title": "Name",
                        "value": message.get('detail').get("Name")
                    }, {
                        "short": True,
                        "title": "Ami ID",
                        "value": message.get("resources")[0]
                    }, {
                        "short": True,
                        "title": "Region",
                        "value": message.get("region")
                    }, {
                        "short": True,
                        "title": "Creation Time",
                        "value": format_date(message.get("time"))
                    }
                ]
            }
        ]
    }

    try:
        r = requests.post(mattermost_url, json=payload)
        return {
            "statusCode": r.status_code,
            "body": r.text
        }
    except requests.RequestException:
        logger.exception("Failed to send data to Mattermost")


def lambda_handler(event, context):
    logger.info("Event: %s", str(event))
    return notify_mattermost(event)
