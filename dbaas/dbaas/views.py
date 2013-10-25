# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals
from django.utils.translation import ugettext_lazy as _
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
from django.http import HttpResponse, HttpResponseRedirect
from django.utils import simplejson
from django.shortcuts import render_to_response
from django.template import RequestContext, loader
from django.core import serializers
from django.contrib.auth.decorators import login_required, permission_required
from django import forms

import logging

LOG = logging.getLogger(__name__)

def home(request):
    
    return render_to_response('dbaas/home.html', locals(), context_instance=RequestContext(request))