#!/usr/bin/env python

import requests
from bs4 import BeautifulSoup


url = 'http://www.radiochopin.org/episodes/item/'
urls = (url + str(i) for i in range(450, 700))
