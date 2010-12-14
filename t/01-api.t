# -----------------------------------------------------------------------------
# Test if Hwloc module can do in principle what is expected
#
# $Id: 01-api.t,v 1.6 2010/12/14 18:41:55 bzbkalli Exp $
# -----------------------------------------------------------------------------

use Test::More;
use strict;
use Sys::Hwloc;

my @export = qw(
		HWLOC_OBJ_CACHE
		HWLOC_OBJ_CORE
		HWLOC_OBJ_MACHINE
		HWLOC_OBJ_MISC
		HWLOC_OBJ_NODE
		HWLOC_OBJ_SOCKET
		HWLOC_OBJ_SYSTEM
		HWLOC_TOPOLOGY_FLAG_IS_THISSYSTEM
		HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM
		HWLOC_TYPE_DEPTH_MULTIPLE
		HWLOC_TYPE_DEPTH_UNKNOWN
		HWLOC_TYPE_UNORDERED

		hwloc_compare_types

		hwloc_topology_check hwloc_topology_destroy hwloc_topology_init hwloc_topology_load

		hwloc_topology_ignore_type hwloc_topology_ignore_type_keep_structure hwloc_topology_ignore_all_keep_structure
		hwloc_topology_set_flags hwloc_topology_set_fsroot hwloc_topology_set_synthetic hwloc_topology_set_xml

		hwloc_topology_get_depth hwloc_get_type_depth hwloc_get_depth_type
		hwloc_get_nbobjs_by_depth hwloc_get_nbobjs_by_type
		hwloc_topology_is_thissystem

		hwloc_get_obj_by_depth hwloc_get_obj_by_type

		hwloc_obj_type_string hwloc_obj_type_of_string
		hwloc_obj_cpuset_sprintf
		hwloc_obj_sprintf

		hwloc_get_type_or_below_depth hwloc_get_type_or_above_depth
		hwloc_get_next_obj_by_depth hwloc_get_next_obj_by_type
		hwloc_get_next_child
		hwloc_get_common_ancestor_obj
		hwloc_obj_is_in_subtree
	      );

if(! HWLOC_API_VERSION()) {
  foreach(qw(
	     HWLOC_OBJ_PROC
	     hwloc_get_system_obj
	    )) {
    push @export, $_;
  }
} else {
  foreach(qw(
	     HWLOC_OBJ_GROUP
	     HWLOC_OBJ_PU
	     hwloc_topology_set_pid
	     hwloc_topology_get_support
	     hwloc_obj_type_sprintf
	     hwloc_obj_attr_sprintf
	     hwloc_get_root_obj
	     hwloc_get_ancestor_obj_by_depth
	     hwloc_get_ancestor_obj_by_type
	     hwloc_get_pu_obj_by_os_index
	    )) {
    push @export, $_;
  }
  if(HWLOC_API_VERSION() > 0x00010000) {
    foreach(qw(
	       hwloc_obj_get_info_by_name
	      )) {
      push @export, $_;
    }
  }
}

if(HWLOC_HAS_XML()) {
  foreach(qw(
	     hwloc_topology_export_xml
	    )) {
    push @export, $_;
  }
}


my @topoMethods = qw(
		     check destroy init load
		     ignore_type ignore_type_keep_structure ignore_all_keep_structure
		     set_flags set_fsroot set_synthetic set_xml

		     get_depth depth
		     get_type_depth type_depth
		     get_depth_type depth_type
		     get_nbobjs_by_depth nbobjs_by_depth
		     get_nbobjs_by_type nbobjs_by_type
		     is_thissystem
		     get_obj_by_depth obj_by_depth
		     get_obj_by_type obj_by_type

		     get_type_or_below_depth type_or_below_depth
		     get_type_or_above_depth type_or_above_depth
		     get_next_obj_by_depth next_obj_by_depth
		     get_next_obj_by_type next_obj_by_type
		     get_common_ancestor_obj common_ancestor_obj
		     obj_is_in_subtree
		    );

if(! HWLOC_API_VERSION()) {
  foreach(qw(
	     system_obj system
	    )) {
    push @topoMethods, $_;
  }
} else {
  foreach(qw(
	     set_pid
	     get_support
	     root_obj root
	     get_pu_obj_by_os_index pu_obj_by_os_index
	    )) {
    push @topoMethods, $_;
  }
}

if(HWLOC_HAS_XML()) {
  foreach(qw(
	     export_xml
	    )) {
    push @topoMethods, $_;
  }
}

my @objMethods = qw(
		    type os_index name attr depth logical_index os_level
		    next_cousin prev_cousin
		    sibling_rank next_sibling prev_sibling
		    arity children first_child last_child
		    sprintf_cpuset
		    get_next_child next_child
		    get_common_ancestor common_ancestor
		    is_in_subtree
		   );

if(! HWLOC_API_VERSION()) {
  foreach(qw(
	     father
	    )) {
    push @objMethods, $_;
  }
} else {
  foreach(qw(
	     memory
	     parent
	     sprintf_type
	     sprintf_attr
	     ancestor_by_depth
	     ancestor_by_type
	    )) {
    push @objMethods, $_;
  }
  if(HWLOC_API_VERSION() > 0x00010000) {
    foreach(qw(
	       infos
	       get_info_by_name info_by_name
	      )) {
      push @objMethods, $_;
    }
  }
}

plan tests => (scalar @export) + (scalar @topoMethods) + (scalar @objMethods);

foreach my $name (@export) {
  can_ok('Sys::Hwloc', $name);
}

foreach my $name (@topoMethods) {
  can_ok('Sys::Hwloc::Topology', $name);
}

foreach my $name (@objMethods) {
  can_ok('Sys::Hwloc::Obj', $name);
}
