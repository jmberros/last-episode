#!/usr/bin/env python

## I generated the wget commands to download the mp3 to disk with this script
## And the I run the wget commands with GNU parallel:

## $ cd <dir of downloads>
## $ ~/repos/last-episode/crawl_radiochopin.py | tee wget_commands.list
## $ parallel --jobs 10 --eta < wget_commands.list

import re
import requests
import redis
import logging
from os import makedirs, getcwd
from os.path import basename, join
from subprocess import run

from bs4 import BeautifulSoup
import coloredlogs
from slugify import slugify


logger = logging.getLogger(__name__)
coloredlogs.install(level='WARNING')

redis_client = redis.StrictRedis()
expiration_time = 60 * 60 * 24 * 30

base_url = 'http://www.radiochopin.org/episodes/item/'

def get_html(url):
    logger.debug('Visit %s' % url)
    response = requests.get(url)
    if not response.ok:
        logger.warning('Code %s for %s' % (response.status_code, url))
    return response.text

def get_and_cache(url):
    if not redis_client.keys(url):
        html = get_html(url)
        redis_client.setex(name=url, value=html, time=expiration_time)
    return redis_client.get(url)

def extract_mp3_url(html):
    soup = BeautifulSoup(html, 'html.parser')

    page_title = soup.find('title').text
    match = re.search(r'Episode (\d+):', page_title)
    ep_number = match.group(1) if match else 0

    for audio in soup.find_all('audio'):
        mp3_name = audio.parent.parent.text.strip()
        match = re.search(r'Radio Chopin Episode \d+: (.+)', mp3_name)
        if match:
            mp3_name = match.group(1)
        slug = slugify(mp3_name, to_lower=True)
        filename = '{:03d}_{}_{}.mp3'.format(int(ep_number),
                                             '1' if match else '2',
                                             slug)
        mp3_url = audio['src']
        yield (filename, mp3_url)

def filenames_and_urls():
    for url in (base_url + str(i) for i in range(450, 700)):
        html = get_and_cache(url)
        yield from extract_mp3_url(html)

def generate_download_command(url, basedir, filename):
    target = join(basedir, filename)
    return 'wget {} -O {} --continue'.format(url, target)

basedir = join(getcwd(), 'chopin_radio')
logger.info('Base directory for downloads: {}'.format(basedir))
makedirs(basedir, exist_ok=True)

for filename, mp3_url in filenames_and_urls():
    if filename.startswith('000'):
        continue
    logger.info('{:65} -> {}'.format(filename, basename(mp3_url)))
    download_command = generate_download_command(mp3_url, basedir, filename)
    logger.info(download_command)
    print(download_command)

