# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals
from django.contrib.auth.backends import ModelBackend
import logging

LOG = logging.getLogger(__name__)

class DbaasBackend(ModelBackend):
    
    def has_perm(self, user_obj, perm, obj=None):
        #LOG.debug("validating perm %s for user %s" % (perm, user_obj))
        if not user_obj.is_active:
            return False
        else:
            return perm in user_obj.get_all_permissions(obj=None)
