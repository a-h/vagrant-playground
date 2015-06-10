from django.http import HttpResponse
from django.shortcuts import render

import logging
logger = logging.getLogger(__name__)

# Create your views here.
def index(request):
    logger.debug("this is a debug message!")
    return HttpResponse("Hello, world. You're at the polls index.")