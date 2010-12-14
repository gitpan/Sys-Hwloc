/*
#  Copyright 2010 Zuse Institute Berlin
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation or under the same terms as perl itself.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#  Please send comments to kallies@zib.de
*/

/* ------------------------------------------------------------------- */
/* $Id: Hwloc.xs,v 1.16 2010/12/14 23:07:14 bzbkalli Exp $              */
/* ------------------------------------------------------------------- */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hwloc.h"

#include "const-c.inc"

#define STOREiv(hv,key,v)  { void *x = hv_store(hv,key,strlen(key),newSViv((IV)v),0);       x = NULL; }
#define STOREuv(hv,key,v)  { void *x = hv_store(hv,key,strlen(key),newSVuv((UV)v),0);       x = NULL; }
#define STOREnv(hv,key,v)  { void *x = hv_store(hv,key,strlen(key),newSVnv((NV)v),0);       x = NULL; }
#define STOREpv(hv,key,v)  { void *x = hv_store(hv,key,strlen(key),newSVpv((char *)v,0),0); x = NULL; }
#define STORErv(hv,key,v)  { void *x = hv_store(hv,key,strlen(key),newRV((SV *)v),0);       x = NULL; }
#define STOREundef(hv,key) { void *x = hv_store(hv,key,strlen(key),&PL_sv_undef,0);         x = NULL; }

static char sbuf[1024];

static SV *hwlocObj2SV(hwloc_obj_t o) {
  SV *sv = NEWSV(0,0);
  sv_setref_pv(sv, "Sys::Hwloc::Obj", (void *)o);
  return sv;
}

static hwloc_obj_t SV2hwlocObj(SV *sv, const char *func, int argi) {
  hwloc_obj_t o = NULL;
  if(SvOK(sv)) {
    if(sv_isobject(sv) && sv_derived_from(sv, "Sys::Hwloc::Obj")) {
      o = INT2PTR(hwloc_obj_t, SvIV((SV*)SvRV(sv)));
    } else {
      croak("%s -- arg %d is not a \"Sys::Hwloc::Obj\" object", func, argi);
    }
  }
  return o;
}

#ifdef HWLOC_API_VERSION
static HV *hwlocTopologySupport2HV(const struct hwloc_topology_support *s) {
  HV *hv = NULL;
  HV *d  = NULL;
  HV *c  = NULL;
#if HWLOC_API_VERSION > 0x00010000
  HV *m  = NULL;
#endif
  if(s) {
    hv = (HV *)sv_2mortal((SV *)newHV());

    d  = (HV *)sv_2mortal((SV *)newHV());
    STOREuv(d, "pu",                     s->discovery->pu);
    STORErv(hv, "discovery", d);

    c  = (HV *)sv_2mortal((SV *)newHV());
    STOREuv(c, "set_thisproc_cpubind",   s->cpubind->set_thisproc_cpubind);
    STOREuv(c, "get_thisproc_cpubind",   s->cpubind->get_thisproc_cpubind);
    STOREuv(c, "set_proc_cpubind",       s->cpubind->set_proc_cpubind);
    STOREuv(c, "get_proc_cpubind",       s->cpubind->get_proc_cpubind);
    STOREuv(c, "set_thisthread_cpubind", s->cpubind->set_thisthread_cpubind);
    STOREuv(c, "get_thisthread_cpubind", s->cpubind->get_thisthread_cpubind);
    STOREuv(c, "set_thread_cpubind",     s->cpubind->set_thread_cpubind);
    STOREuv(c, "get_thread_cpubind",     s->cpubind->get_thread_cpubind);
    STORErv(hv, "cpubind", c);

#if HWLOC_API_VERSION > 0x00010000
    m  = (HV *)sv_2mortal((SV *)newHV());
    STOREuv(m, "set_thisproc_membind",   s->membind->set_thisproc_membind);
    STOREuv(m, "get_thisproc_membind",   s->membind->get_thisproc_membind);
    STOREuv(m, "set_proc_membind",       s->membind->set_proc_membind);
    STOREuv(m, "get_proc_membind",       s->membind->get_proc_membind);
    STOREuv(m, "set_thisthread_membind", s->membind->set_thisthread_membind);
    STOREuv(m, "get_thisthread_membind", s->membind->get_thisthread_membind);
    STOREuv(m, "set_area_membind",       s->membind->set_area_membind);
    STOREuv(m, "get_area_membind",       s->membind->get_area_membind);
    STOREuv(m, "alloc_membind",          s->membind->alloc_membind);
    STOREuv(m, "firsttouch_membind",     s->membind->firsttouch_membind);
    STOREuv(m, "bind_membind",           s->membind->bind_membind);
    STOREuv(m, "interleave_membind",     s->membind->interleave_membind);
    STOREuv(m, "replicate_membind",      s->membind->replicate_membind);
    STOREuv(m, "nexttouch_membind",      s->membind->nexttouch_membind);
    STOREuv(m, "migrate_membind",        s->membind->migrate_membind);
    STORErv(hv, "membind", m);
#endif
  }
  return hv;
}

static HV *hwlocObjMemoryPageType2HV(struct hwloc_obj_memory_page_type_s *s) {
  HV *hv = (HV *)sv_2mortal((SV *)newHV());
  STOREuv(hv, "size",  s->size);
  STOREuv(hv, "count", s->count);
  return hv;
}

static HV *hwlocObjMemory2HV(struct hwloc_obj_memory_s *s) {
  HV *hv = (HV *)sv_2mortal((SV *)newHV());
  AV *av = (AV *)sv_2mortal((SV *)newAV());
  int i;
  STOREuv(hv, "total_memory",   s->total_memory);
  STOREuv(hv, "local_memory",   s->local_memory);
  STOREuv(hv, "page_types_len", s->page_types_len);
  STORErv(hv, "page_types",     av);
  for(i = 0; i < s->page_types_len; i++)
    av_push(av, newRV((SV *)hwlocObjMemoryPageType2HV(&s->page_types[i])));
  return hv;
}
#endif

static HV *hwlocObjAttr2HV(union hwloc_obj_attr_u *s, hwloc_obj_type_t type) {
  HV *hv = (HV *)sv_2mortal((SV *)newHV());
  HV *a  = NULL;
  if(s) {
    switch(type) {
#ifndef HWLOC_API_VERSION
      case HWLOC_OBJ_MACHINE:
	a = (HV *)sv_2mortal((SV *)newHV());
	STORErv(hv, "machine", a);
	if(s->machine.dmi_board_vendor) {
	  STOREpv(a, "dmi_board_vendor", s->machine.dmi_board_vendor);
	} else {
	  STOREundef(a, "dmi_board_vendor");
	}
	if(s->machine.dmi_board_name) {
	  STOREpv(a, "dmi_board_name",   s->machine.dmi_board_name);
	} else {
	  STOREundef(a, "dmi_board_name");
	}
        STOREuv(a, "memory_kB",          s->machine.memory_kB);
        STOREuv(a, "huge_page_free",     s->machine.huge_page_free);
        STOREuv(a, "huge_page_size_kB",  s->machine.huge_page_size_kB);
	break;
#else
#if HWLOC_API_VERSION == 0x00010000
      case HWLOC_OBJ_MACHINE:
	a = (HV *)sv_2mortal((SV *)newHV());
	STORErv(hv, "machine", a);
	if(s->machine.dmi_board_vendor) {
	  STOREpv(a, "dmi_board_vendor", s->machine.dmi_board_vendor);
	} else {
	  STOREundef(a, "dmi_board_vendor");
	}
	if(s->machine.dmi_board_name) {
	  STOREpv(a, "dmi_board_name",   s->machine.dmi_board_name);
	} else {
	  STOREundef(a, "dmi_board_name");
	}
#endif
#endif
      case HWLOC_OBJ_CACHE:
	a = (HV *)sv_2mortal((SV *)newHV());
	STORErv(hv, "cache", a);
	STOREuv(a, "depth",                s->cache.depth);
#ifndef HWLOC_API_VERSION
	STOREuv(a, "memory_kB",            s->cache.memory_kB);
#else
	STOREuv(a, "size",                 s->cache.size);
#if HWLOC_API_VERSION > 0x00010000
	STOREuv(a, "linesize",             s->cache.linesize);
#endif
#endif
        break;
#ifndef HWLOC_API_VERSION
      case HWLOC_OBJ_MISC:
	a = (HV *)sv_2mortal((SV *)newHV());
	STORErv(hv, "misc", a);
        STOREuv(a, "depth",                 s->misc.depth);
	break;
      case HWLOC_OBJ_NODE:
	a = (HV *)sv_2mortal((SV *)newHV());
	STORErv(hv, "node", a);
        STOREuv(a, "memory_kB",             s->node.memory_kB);
        STOREuv(a, "huge_page_free",        s->node.huge_page_free);
	break;
#endif
#ifdef HWLOC_API_VERSION
      case HWLOC_OBJ_GROUP:
	a = (HV *)sv_2mortal((SV *)newHV());
	STORErv(hv, "group", a);
        STOREuv(a, "depth",                s->group.depth);
	break;
#endif

      default:
        break;
    }
  }
  return hv;
}

#if HWLOC_API_VERSION > 0x00010000
static HV *hwlocObjInfos2HV(struct hwloc_obj_info_s *s, unsigned n) {
  HV *hv = (HV *)sv_2mortal((SV *)newHV());
  int i;
  for(i = 0; i < n; i++) {
    if(s[i].name) {
      if(s[i].value) {
	STOREpv(hv, s[i].name, s[i].value);
      } else {
	STOREundef(hv, s[i].name);
      }
    }
  }
  return hv;
}
#endif

/* =================================================================== */
/* XS Code below                                                       */
/* =================================================================== */

MODULE = Sys::Hwloc                  PACKAGE = Sys::Hwloc

INCLUDE: const-xs.inc

 # -------------------------------------------------------------------
 # Topology object types
 # -------------------------------------------------------------------

int
hwloc_compare_types(type1,type2)
  hwloc_obj_type_t type1
  hwloc_obj_type_t type2
  PROTOTYPE: $$
  CODE:
    RETVAL = hwloc_compare_types(type1,type2);
  OUTPUT:
    RETVAL

 # -------------------------------------------------------------------
 # Create and destroy topologies
 # -------------------------------------------------------------------

void
hwloc_topology_check(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::check = 1
  PPCODE:
    hwloc_topology_check(topo);


void
hwloc_topology_destroy(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::destroy = 1
  PPCODE:
    hwloc_topology_destroy(topo);


hwloc_topology_t
hwloc_topology_init()
  PROTOTYPE:
  PREINIT:
    hwloc_topology_t t = NULL;
  CODE:  
    if(! hwloc_topology_init(&t))
      RETVAL = t;
    else
      XSRETURN_UNDEF;
  OUTPUT:
     RETVAL


int
hwloc_topology_load(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::load = 1
  CODE:
    RETVAL = hwloc_topology_load(topo);
  OUTPUT:
    RETVAL


 # -------------------------------------------------------------------
 # Configure topology detection
 # -------------------------------------------------------------------

int
hwloc_topology_ignore_type(topo,type)
  hwloc_topology_t topo
  hwloc_obj_type_t type
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::ignore_type = 1
  CODE:
    RETVAL = hwloc_topology_ignore_type(topo,type);
  OUTPUT:
    RETVAL


int
hwloc_topology_ignore_type_keep_structure(topo,type)
  hwloc_topology_t topo
  hwloc_obj_type_t type
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::ignore_type_keep_structure = 1
  CODE:
    RETVAL = hwloc_topology_ignore_type_keep_structure(topo,type);
  OUTPUT:
    RETVAL


int
hwloc_topology_ignore_all_keep_structure(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::ignore_all_keep_structure = 1
  CODE:
    RETVAL = hwloc_topology_ignore_all_keep_structure(topo);
  OUTPUT:
    RETVAL


int
hwloc_topology_set_flags(topo,flags)
  hwloc_topology_t topo
  unsigned         flags
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::set_flags = 1
  CODE:
    RETVAL = hwloc_topology_set_flags(topo,flags);
  OUTPUT:
    RETVAL


int
hwloc_topology_set_fsroot(topo,path)
  hwloc_topology_t topo
  const char      *path
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::set_fsroot = 1
  CODE:
    RETVAL = hwloc_topology_set_fsroot(topo,path);
  OUTPUT:
    RETVAL


#ifdef HWLOC_API_VERSION
int
hwloc_topology_set_pid(topo,pid)
  hwloc_topology_t topo
  pid_t            pid
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::set_pid = 1
  CODE:
    RETVAL = hwloc_topology_set_pid(topo,pid);
  OUTPUT:
    RETVAL

#endif


int
hwloc_topology_set_synthetic(topo,string)
  hwloc_topology_t  topo
  const char       *string
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::set_synthetic = 1
  CODE:
    RETVAL = hwloc_topology_set_synthetic(topo,string);
  OUTPUT:
    RETVAL


int
hwloc_topology_set_xml(topo,path)
  hwloc_topology_t  topo
  const char       *path
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::set_xml = 1
  CODE:
    RETVAL = hwloc_topology_set_xml(topo,path);
  OUTPUT:
    RETVAL


#ifdef HWLOC_API_VERSION
SV *
hwloc_topology_get_support(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::get_support = 1
  PREINIT:
    const struct hwloc_topology_support *st = NULL;
  CODE:
    if((st = hwloc_topology_get_support(topo)))
      RETVAL = newRV((SV *)hwlocTopologySupport2HV(st));
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

#endif


 # -------------------------------------------------------------------
 # Tinker with topologies
 # ToDo: hwloc_topology_insert_misc_object_by_cpuset
 # ToDo: hwloc_topology_insert_misc_object_by_parent
 # -------------------------------------------------------------------

#if HWLOC_HAS_XML
void
hwloc_topology_export_xml(topo,path)
  hwloc_topology_t  topo
  const char       *path
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::export_xml = 1
  PPCODE:
    hwloc_topology_export_xml(topo,path);

#endif


 # -------------------------------------------------------------------
 # Get some topology information
 # -------------------------------------------------------------------

unsigned
hwloc_topology_get_depth(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::get_depth = 1
    Sys::Hwloc::Topology::depth     = 2
  CODE:
    RETVAL = hwloc_topology_get_depth(topo);
  OUTPUT:
    RETVAL


int
hwloc_get_type_depth(topo,type)
  hwloc_topology_t topo
  hwloc_obj_type_t type
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_type_depth = 1
    Sys::Hwloc::Topology::type_depth     = 2
  CODE:
    RETVAL = hwloc_get_type_depth(topo,type);
  OUTPUT:
    RETVAL


int
hwloc_get_depth_type(topo,depth)
  hwloc_topology_t topo
  unsigned         depth
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_depth_type = 1
    Sys::Hwloc::Topology::depth_type     = 2
  CODE:
  RETVAL = hwloc_get_depth_type(topo,depth);
  OUTPUT:
    RETVAL


unsigned
hwloc_get_nbobjs_by_depth(topo,depth)
  hwloc_topology_t topo
  unsigned         depth
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_nbobjs_by_depth = 1
    Sys::Hwloc::Topology::nbobjs_by_depth     = 2
  CODE:
  RETVAL = hwloc_get_nbobjs_by_depth(topo,depth);
  OUTPUT:
    RETVAL


int
hwloc_get_nbobjs_by_type(topo,type)
  hwloc_topology_t topo
  hwloc_obj_type_t type
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_nbobjs_by_type = 1
    Sys::Hwloc::Topology::nbobjs_by_type     = 2
  CODE:
  RETVAL = hwloc_get_nbobjs_by_type(topo,type);
  OUTPUT:
    RETVAL


int
hwloc_topology_is_thissystem(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::is_thissystem = 1
  CODE:
    RETVAL = hwloc_topology_is_thissystem(topo);
  OUTPUT:
    RETVAL


 # -------------------------------------------------------------------
 # Retrieve objects
 # -------------------------------------------------------------------

hwloc_obj_t
hwloc_get_obj_by_depth(topo,depth,idx)
  hwloc_topology_t  topo
  unsigned          depth
  unsigned          idx
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_obj_by_depth = 1
    Sys::Hwloc::Topology::obj_by_depth     = 2
  CODE:
    RETVAL = hwloc_get_obj_by_depth(topo,depth,idx);
  OUTPUT:
    RETVAL


hwloc_obj_t
hwloc_get_obj_by_type(topo,type,idx)
  hwloc_topology_t  topo
  hwloc_obj_type_t  type
  unsigned          idx
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_obj_by_type = 1
    Sys::Hwloc::Topology::obj_by_type     = 2
  CODE:
    RETVAL = hwloc_get_obj_by_type(topo,type,idx);
  OUTPUT:
    RETVAL



 # -------------------------------------------------------------------
 # Object/string conversion
 # -------------------------------------------------------------------

const char *
hwloc_obj_type_string(type)
  hwloc_obj_type_t type
  PROTOTYPE: $
  CODE:
    const char *s;
    if((s = hwloc_obj_type_string(type)))
      RETVAL = s;
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL


int
hwloc_obj_type_of_string(string)
  const char *string
  PROTOTYPE: $
  CODE:
    RETVAL = hwloc_obj_type_of_string(string);
  OUTPUT:
    RETVAL


#ifdef HWLOC_API_VERSION
char *
hwloc_obj_type_sprintf(obj, ...)
  hwloc_obj_t obj
  PROTOTYPE: $;$
  ALIAS:
    Sys::Hwloc::Obj::sprintf_type = 1
  PREINIT:
    int rc;
    int verbose = 0;
  CODE:
    if((items > 1) && (SvIOK(ST(1))))
      verbose = SvIV(ST(1));
    if((rc = hwloc_obj_type_snprintf(sbuf, sizeof(sbuf), obj, verbose)) == -1)
      XSRETURN_UNDEF;
    else
      RETVAL = sbuf;
  OUTPUT:
    RETVAL

#endif


#ifdef HWLOC_API_VERSION
char *
hwloc_obj_attr_sprintf(obj, ...)
  hwloc_obj_t obj
  PROTOTYPE: $;$$
  ALIAS:
    Sys::Hwloc::Obj::sprintf_attr = 1
  PREINIT:
    int   rc;
    char *separator = "";
    int   verbose   = 0;
  CODE:
    if((items > 1) && (SvOK(ST(1))))
      separator = SvPV_nolen(ST(1));
    if((items > 2) && (SvIOK(ST(2))))
      verbose   = SvIV(ST(2));
    if((rc = hwloc_obj_attr_snprintf(sbuf, sizeof(sbuf), obj, separator, verbose)) == -1)
      XSRETURN_UNDEF;
    else
      RETVAL = sbuf;
  OUTPUT:
    RETVAL

#endif


char *
hwloc_obj_sprintf(topo,obj, ...)
  hwloc_topology_t topo
  hwloc_obj_t      obj
  PROTOTYPE: $$;$$
  ALIAS:
    Sys::Hwloc::Topology::sprintf_obj = 1
  PREINIT:
    int   rc;
    char *prefix  = NULL;
    int   verbose = 0;
  CODE:
    if((items > 2) && (SvOK(ST(2))))
      prefix  = SvPV_nolen(ST(2));
    if((items > 3) && (SvIOK(ST(3))))
      verbose = SvIV(ST(3));
    if((rc = hwloc_obj_snprintf(sbuf, sizeof(sbuf), topo, obj, prefix, verbose)) == -1)
      XSRETURN_UNDEF;
    else
      RETVAL = sbuf;
  OUTPUT:
    RETVAL


char *
hwloc_obj_cpuset_sprintf(...)
  PROTOTYPE: DISABLE
  ALIAS:
    Sys::Hwloc::Obj::sprintf_cpuset = 1
  CODE:
    hwloc_obj_t *objs = NULL;
    int          i;
    int          rc;
    if(items > 0) {
      if((ix == 1) && (items > 1))
	croak("Usage: sprintf_cpuset()");
      if((objs = (hwloc_obj_t *)malloc(items * sizeof(hwloc_obj_t *))) == NULL)
	croak("Failed to allocate memory");
      for(i = 0; i < items; i++) {
	if((objs[i] = SV2hwlocObj(ST(i), "Sys::Hwloc::hwloc_obj_cpuset_sprintf()", i)) == NULL)
	  croak("Sys::Hwloc::hwloc_obj_cpuset_sprintf() -- arg %d is not a \"Sys::Hwloc::Obj\" object", i);
      }
    } else {
      if(ix)
	croak("Not enough arguments for Sys::Hwloc::Obj::sprintf_cpuset");
    }
    if((rc = hwloc_obj_cpuset_snprintf(sbuf, sizeof(sbuf), items, objs)) == -1) {
      if(objs)
        free(objs);
      XSRETURN_UNDEF;
    } else {
      RETVAL = sbuf;
      if(objs)
	free(objs);
    }
  OUTPUT:
    RETVAL


#if HWLOC_API_VERSION > 0x00010000
char *
hwloc_obj_get_info_by_name(obj,name)
  hwloc_obj_t  obj
  const char  *name
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Obj::get_info_by_name = 1
    Sys::Hwloc::Obj::info_by_name     = 2
  CODE:
    RETVAL = hwloc_obj_get_info_by_name(obj,name);
  OUTPUT:
    RETVAL

#endif
  

 # -------------------------------------------------------------------
 # Binding
 # ToDo: hwloc_set_cpubind
 # ToDo: hwloc_get_cpubind
 # ToDo: hwloc_set_proc_cpubind
 # ToDo: hwloc_get_proc_cpubind
 # -------------------------------------------------------------------

 # -------------------------------------------------------------------
 # Object type helpers
 # -------------------------------------------------------------------

int
hwloc_get_type_or_below_depth(topo,type)
  hwloc_topology_t topo
  hwloc_obj_type_t type
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_type_or_below_depth = 1
    Sys::Hwloc::Topology::type_or_below_depth     = 2
  CODE:
    RETVAL = hwloc_get_type_or_below_depth(topo,type);
  OUTPUT:
    RETVAL


int
hwloc_get_type_or_above_depth(topo,type)
  hwloc_topology_t topo
  hwloc_obj_type_t type
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_type_or_above_depth = 1
    Sys::Hwloc::Topology::type_or_above_depth     = 2
  CODE:
    RETVAL = hwloc_get_type_or_above_depth(topo,type);
  OUTPUT:
    RETVAL


 # -------------------------------------------------------------------
 # Basic traversal helpers
 # -------------------------------------------------------------------


#ifndef HWLOC_API_VERSION
hwloc_obj_t
hwloc_get_system_obj(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::system_obj = 1
    Sys::Hwloc::Topology::system     = 2
  CODE:
    RETVAL = hwloc_get_system_obj(topo);
  OUTPUT:
    RETVAL

#else
hwloc_obj_t
hwloc_get_root_obj(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::root_obj   = 1
    Sys::Hwloc::Topology::root       = 2
  CODE:
    RETVAL = hwloc_get_root_obj(topo);
  OUTPUT:
    RETVAL

#endif


#ifdef HWLOC_API_VERSION
hwloc_obj_t
hwloc_get_ancestor_obj_by_depth(obj,depth)
  hwloc_obj_t obj
  unsigned    depth
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Obj::ancestor_by_depth = 1
  CODE:
    RETVAL = hwloc_get_ancestor_obj_by_depth(NULL,depth,obj);
  OUTPUT:
    RETVAL

#endif


#ifdef HWLOC_API_VERSION
hwloc_obj_t
hwloc_get_ancestor_obj_by_type(obj,type)
  hwloc_obj_t      obj
  hwloc_obj_type_t type
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Obj::ancestor_by_type = 1
  CODE:
    RETVAL = hwloc_get_ancestor_obj_by_type(NULL,type,obj);
  OUTPUT:
    RETVAL

#endif


hwloc_obj_t
hwloc_get_next_obj_by_depth(topo,depth,prev)
  hwloc_topology_t topo
  unsigned         depth
  SV              *prev
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_next_obj_by_depth = 1
    Sys::Hwloc::Topology::next_obj_by_depth     = 2
  PREINIT:
    hwloc_obj_t    o = NULL;
  CODE:
    o      = SV2hwlocObj(prev, "Sys::Hwloc::hwloc_get_next_obj_by_depth()", 3);
    RETVAL = hwloc_get_next_obj_by_depth(topo,depth,o);
  OUTPUT:
    RETVAL


hwloc_obj_t
hwloc_get_next_obj_by_type(topo,type,prev)
  hwloc_topology_t topo
  hwloc_obj_type_t type
  SV              *prev
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_next_obj_by_type = 1
    Sys::Hwloc::Topology::next_obj_by_type     = 2
  PREINIT:
    hwloc_obj_t    o = NULL;
  CODE:
    o      = SV2hwlocObj(prev, "Sys::Hwloc::hwloc_get_next_obj_by_type()", 3);
    RETVAL = hwloc_get_next_obj_by_type(topo,type,o);
  OUTPUT:
    RETVAL


#ifdef HWLOC_API_VERSION
hwloc_obj_t
hwloc_get_pu_obj_by_os_index(topo,idx)
  hwloc_topology_t topo
  unsigned         idx
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_pu_obj_by_os_index = 1
    Sys::Hwloc::Topology::pu_obj_by_os_index     = 2
  CODE:
    RETVAL = hwloc_get_pu_obj_by_os_index(topo,idx);
  OUTPUT:
    RETVAL

#endif


hwloc_obj_t
hwloc_get_next_child(obj,prev)
  hwloc_obj_t   obj
  SV           *prev
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Obj::get_next_child = 1
    Sys::Hwloc::Obj::next_child     = 2
  PREINIT:
    hwloc_obj_t o = NULL;
  CODE:
    o      = SV2hwlocObj(prev, "Sys::Hwloc::hwloc_get_next_child()", 2);
    RETVAL = hwloc_get_next_child(NULL,obj,o);
  OUTPUT:
    RETVAL


hwloc_obj_t
hwloc_get_common_ancestor_obj(topo,obj1,obj2)
  hwloc_topology_t topo
  hwloc_obj_t      obj1
  hwloc_obj_t      obj2
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_common_ancestor_obj = 1
    Sys::Hwloc::Topology::common_ancestor_obj     = 2
  CODE:
    RETVAL = hwloc_get_common_ancestor_obj(NULL,obj1,obj2);
  OUTPUT:
    RETVAL


int
hwloc_obj_is_in_subtree(topo,obj1,obj2)
  hwloc_topology_t topo
  hwloc_obj_t      obj1
  hwloc_obj_t      obj2
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::obj_is_in_subtree = 1
  CODE:
    RETVAL = hwloc_obj_is_in_subtree(NULL,obj1,obj2);
  OUTPUT:
    RETVAL


 # ===================================================================
 # PACKAGE Sys::Hwloc::Topology, OO interface of hwloc_topology_t
 # ===================================================================

MODULE = Sys::Hwloc                  PACKAGE = Sys::Hwloc::Topology

 # -------------------------------------------------------------------
 # Constructor only, other methods are aliased from package Sys::Hwloc
 # -------------------------------------------------------------------

hwloc_topology_t
init(void)
  PROTOTYPE:
  ALIAS:
    new = 1
  PREINIT:
    hwloc_topology_t t = NULL;
  CODE:  
    if(! hwloc_topology_init(&t))
      RETVAL = t;
    else
      XSRETURN_UNDEF;
  OUTPUT:
     RETVAL



 # ===================================================================
 # PACKAGE Sys::Hwloc::Obj
 # ===================================================================

MODULE = Sys::Hwloc                  PACKAGE = Sys::Hwloc::Obj

hwloc_obj_type_t
type(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->type;
  OUTPUT:
    RETVAL


unsigned
os_index(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->os_index;
  OUTPUT:
    RETVAL


char *
name(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    if(o->name)
      RETVAL = o->name;
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL


#ifdef HWLOC_API_VERSION
SV *
memory(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = newRV((SV *)hwlocObjMemory2HV(&o->memory));
  OUTPUT:
    RETVAL

#endif


SV *
attr(o)
  hwloc_obj_t o
  PROTOTYPE: $
  PREINIT:
    HV *hv = NULL;
  CODE:
    if((hv = hwlocObjAttr2HV(o->attr, o->type)))
      RETVAL = newRV((SV *)hv);
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL


unsigned
depth(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->depth;
  OUTPUT:
    RETVAL


unsigned
logical_index(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->logical_index;
  OUTPUT:
    RETVAL


int
os_level(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->os_level;
  OUTPUT:
    RETVAL


hwloc_obj_t
next_cousin(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->next_cousin;
  OUTPUT:
    RETVAL


hwloc_obj_t
prev_cousin(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->prev_cousin;
  OUTPUT:
    RETVAL


#ifndef HWLOC_API_VERSION
hwloc_obj_t
father(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->father;
  OUTPUT:
    RETVAL

#else
hwloc_obj_t
parent(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->parent;
  OUTPUT:
    RETVAL

#endif


unsigned
sibling_rank(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->sibling_rank;
  OUTPUT:
    RETVAL


hwloc_obj_t
next_sibling(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->next_sibling;
  OUTPUT:
    RETVAL


hwloc_obj_t
prev_sibling(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->prev_sibling;
  OUTPUT:
    RETVAL


unsigned
arity(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->arity;
  OUTPUT:
    RETVAL


void
children(o)
  hwloc_obj_t o
  PROTOTYPE: $
  PREINIT:
    int i;
  PPCODE:
    EXTEND(SP, o->arity);
    for(i = 0; i < o->arity; i++)
      PUSHs(sv_2mortal(hwlocObj2SV(o->children[i])));
    XSRETURN(o->arity);


hwloc_obj_t
first_child(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->first_child;
  OUTPUT:
    RETVAL


hwloc_obj_t
last_child(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->last_child;
  OUTPUT:
    RETVAL


#if HWLOC_API_VERSION > 0x00010000
SV *
infos(o)
  hwloc_obj_t o
  PROTOTYPE: $
  PREINIT:
    HV *hv = NULL;
  CODE:
    if((hv = hwlocObjInfos2HV(o->infos, o->infos_count)))
      RETVAL = newRV((SV *)hv);
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

#endif


hwloc_obj_t
get_common_ancestor(o1,o2)
  hwloc_obj_t o1
  hwloc_obj_t o2
  PROTOTYPE: $$
  ALIAS:
    common_ancestor = 1
  CODE:
    RETVAL = hwloc_get_common_ancestor_obj(NULL,o1,o2);
  OUTPUT:
    RETVAL


int
is_in_subtree(o1,o2)
  hwloc_obj_t o1
  hwloc_obj_t o2
  PROTOTYPE: $$
  CODE:
    RETVAL = hwloc_obj_is_in_subtree(NULL,o1,o2);
  OUTPUT:
    RETVAL

