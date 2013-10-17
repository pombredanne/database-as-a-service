# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals
from django.utils.translation import ugettext_lazy as _
import logging

from rest_framework import viewsets
from rest_framework.response import Response
# from rest_framework.decorators import action, link
from rest_framework.decorators import api_view

from physical.models import Engine, EngineType

LOG = logging.getLogger(__name__)

def __check_service_availability(engine_name, engine_version):
    """
    Checks the availability of the service.
    Returns engine_type for the service or a response error 500 if not found.
    
    """
    engine = None
    try:
        engine_type = EngineType.objects.get(name=engine_name)
        engine = Engine.objects.get(engine_type=engine_type, version=engine_version)
    except EngineType.DoesNotExist:
        LOG.warning("endpoint not available for %s_%s" % (engine_name, engine_version))
    except Engine.DoesNotExist:
        LOG.warning("endpoint not available for %s_%s" % (engine_name, engine_version))
    
    return engine

@api_view(['GET'])
def status(request, engine_name=None, engine_version=None):
    engine = __check_service_availability(engine_name, engine_version)
    if not engine:
        return Response(data={"error": "endpoint not available for %s(%s)" % (engine_name, engine_version)}, status=500)

    return Response(data={"status": "ok"}, status=204)
        
@api_view(['POST'])
def service_add(request, engine_name=None, engine_version=None):
    """
    Responds to tsuru's service_add call.
    
    Creates a new instance.
    
    Return codes:
    201: when the instance is successfully created. You don’t need to include any content in the response body.
    500: in case of any failure in the creation process. Make sure you include an explanation for the failure in the response body.
    """
    LOG.info("Call for %s(%s) api" % (engine_name, engine_version))
    
    LOG.debug("request DATA: %s" % request.DATA)
    LOG.debug("request QUERY_PARAMS: %s" % request.QUERY_PARAMS)
    LOG.debug("request content-type: %s" % request.content_type)
    # LOG.debug("request meta: %s" % request.META)
    engine = __check_service_availability(engine_name, engine_version)
    if not engine:
        return Response(data={"error": "endpoint not available for %s(%s)" % (engine_name, engine_version)}, status=500)
    
    data = request.DATA
    service_name = data.get('name', None)
    LOG.info("creating service %s" % (service_name))
    try:
        #Instance.provision(engine=,name=service_name)
        return Response({"status": "ok", 
                        "engine_type" : engine.engine_type.name,
                        "version" : engine.version}, status=201)
    except Exception, e:
        LOG.error("error provisioning instance %s: %s" % (service_name, e))
