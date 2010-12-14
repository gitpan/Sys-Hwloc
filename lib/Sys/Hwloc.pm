################################################################################
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
#
################################################################################
# $Id: Hwloc.pm,v 1.5 2010/12/14 23:07:14 bzbkalli Exp $
################################################################################

package Sys::Hwloc;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA     = qw(Exporter);

our @EXPORT  = qw(
		  HWLOC_API_VERSION
		  HWLOC_HAS_XML

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

		  hwloc_topology_export_xml

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
		  hwloc_get_common_ancestor_obj hwloc_obj_is_in_subtree

                 );

{
  if(! HWLOC_API_VERSION()) {
    foreach(qw(
	       HWLOC_OBJ_PROC
	       hwloc_get_system_obj
	      )) {
      push @EXPORT, $_;
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
      push @EXPORT, $_;
    }
    if(HWLOC_API_VERSION() > 0x00010000) {
      foreach(qw(
		 hwloc_obj_get_info_by_name
		)) {
	push @EXPORT, $_;
      }
    }

  }
}

our $VERSION = '0.04';

sub AUTOLOAD {
  # This AUTOLOAD is used to 'autoload' constants from the constant()
  # XS function.

  my $constname;
  our $AUTOLOAD;
  ($constname = $AUTOLOAD) =~ s/.*:://;
  croak "&Hwloc::constant not defined" if $constname eq 'constant';
  my ($error, $val) = constant($constname);
  if ($error) { croak $error; }
  {
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
  }
  goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Sys::Hwloc', $VERSION);

# Preloaded methods go here.

sub HWLOC_API_VERSION { @HWLOC_API_VERSION@ }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

=pod

=head1 NAME

Sys::Hwloc - Perl Access to Portable Hardware Locality (hwloc)

=head1 SYNOPSIS

       use Sys::Hwloc;

       # Load topology
       $topology = hwloc_topology_init();
       die "Failed to init topology" unless $topology;
       $rc = hwloc_topology_load($topology);
       die "Failed to load topology" if $rc;

       # Determine number of sockets and processors
       $nProcs   = hwloc_get_nbobjs_by_type($topology, HWLOC_OBJ_PU);
       $nSockets = hwloc_get_nbobjs_by_type($topology, HWLOC_OBJ_SOCKET);
       die "Failed to determine number of processors" unless $nProcs;
       die "Failed to determine number of sockets"    unless $nSockets;
       printf "Topology contains %d processors on %d sockets.\n", $nProcs, $nSockets;

       # Compute the amount of cache of the first logical processor
       $levels = 0;
       $size   = 0;
       for($obj = hwloc_get_obj_by_type($topology, HWLOC_OBJ_PU, 0);
           $obj;
           $obj = $obj->parent
          ) {
         next unless $obj->type == HWLOC_OBJ_CACHE;
         $levels++;
         $size += $obj->attr->{cache}->{size};
       }
       printf "Logical CPU 0 has %d caches with total %dkB.\n", $levels, $size / 1024;

       # Destroy topology
       hwloc_topology_destroy($topology);


or going the OO-ish way:

       use Sys::Hwloc;

       # Load topology
       $topology = Sys::Hwloc::Topology->init;
       die "Failed to init topology" unless $topology;
       $rc = $topology->load;
       die "Failed to load topology" if $rc;

       # Determine number of sockets and processors
       $nProcs   = $topology->get_nbobjs_by_type(HWLOC_OBJ_PU);
       $nSockets = $topology->get_nbobjs_by_type(HWLOC_OBJ_SOCKET);
       die "Failed to determine number of processors" unless $nProcs;
       die "Failed to determine number of sockets"    unless $nSockets;
       printf "Topology contains %d processors on %d sockets.\n", $nProcs, $nSockets;

       # Stringify the left side of the topology tree
       for($obj = $topology->get_obj_by_depth(0,0);
           $obj;
           $obj = $obj->first_child
          ) {
         printf("%*s%s#%d (%s)\n",
	        $obj->depth, '',
	        $obj->sprintf_type,
	        $obj->logical_index,
	        $obj->sprintf_attr('; ',1),
	       );
       }

       # Destroy topology
       $topology->destroy;


=head1 DESCRIPTION

The Hwloc module provides a perl API for the hwloc C API.

Visit L<http://www.open-mpi.org/projects/hwloc> for information about hwloc.

The module provides access to the functions of the hwloc API as well
as an object-oriented interface to hwloc_topology and hwloc_obj objects.

=head1 CONSTANTS

The following constants are exported by the Hwloc module:

=head2 Type of topology objects

        HWLOC_OBJ_MACHINE
        HWLOC_OBJ_NODE
        HWLOC_OBJ_SOCKET
        HWLOC_OBJ_CACHE
        HWLOC_OBJ_CORE
        HWLOC_OBJ_PROC            before hwloc 1.0
        HWLOC_OBJ_PU              since  hwloc 1.0
        HWLOC_OBJ_GROUP           since  hwloc 1.0
        HWLOC_OBJ_MISC


=head2 Topology flags

        HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM
        HWLOC_TOPOLOGY_FLAG_IS_THISSYSTEM

=head2 Misc

        HWLOC_API_VERSION         undef before hwloc 1.0
        HWLOC_HAS_XML             hwloc built with XML or not
        HWLOC_TYPE_UNORDERED
        HWLOC_TYPE_DEPTH_UNKNOWN
        HWLOC_TYPE_DEPTH_MULTIPLE

=head1 METHODS

The exported methods are listed below.

Each listing contains the methods that conform to the hwloc C API,
and the corresponding Hwloc perl API OO-ish methods, if implemented.

=head2 Topoogy object types

        $val  = hwloc_compare_types($type1,$type2)

=head2 Create and destroy topologies

        $t    = hwloc_topology_init()
        $rc   = hwloc_topology_load($t)
        hwloc_topology_check($t)
        hwloc_topology_destroy($t)

        $t    = Sys::Hwloc::Topology->init
        $t    = Sys::Hwloc::Topology->new
        $rc   = $t->load
        $t->check
        $t->destroy

=head2 Configure topology detection

        $rc   = hwloc_topology_ignore_type($t,$type)
        $rc   = hwloc_topology_ignore_type_keep_structure($t,$type)
        $rc   = hwloc_topology_ignore_all_keep_structure($t)
        $rc   = hwloc_topology_set_flags($t,$flags)
        $rc   = hwloc_topology_set_fsroot($t,$path)
        $rc   = hwloc_topology_set_pid($t,$pid)            since  hwloc 1.0
        $rc   = hwloc_topology_set_synthetic($t,$string)
        $rc   = hwloc_topology_set_xml($t,$path)
        $href = hwloc_topology_get_support($t)             since  hwloc 1.0

        $rc   = $t->ignore_type($type)
        $rc   = $t->ignore_type_keep_structure($type)
        $rc   = $t->ignore_all_keep_structure
        $rc   = $t->set_flags($flags)
        $rc   = $t->set_fsroot($path)
        $rc   = $t->set_pid($pid)
        $rc   = $t->set_synthetic($string)
        $rc   = $t->set_xml($path)
        $href = $t->get_support($t)

=head2 Tinker with topologies

        hwloc_topology_export_xml($t,$path)               if HWLOC_HAS_XML

        $t->export_xml($path)                             if HWLOC_HAS_XML

=head2 Get some topology information

        $val  = hwloc_topology_get_depth($t)
        $val  = hwloc_topology_get_type_depth($t,$type)
        $val  = hwloc_topology_get_depth_type($t,$depth)
        $val  = hwloc_get_nbobjs_by_depth($t,$depth)
        $val  = hwloc_get_nbobjs_by_type($t,$type)
        $rc   = hwloc_topology_is_thissystem($t)

        $val  = $t->depth
        $val  = $t->get_type_depth($type)
        $val  = $t->get_depth_type($depth)
        $val  = $t->get_nbobjs_by_depth($depth)
        $val  = $t->get_nbobjs_by_type($type)
        $rc   = $t->is_thissystem

=head2 Retrieve topology objects

        $obj  = hwloc_get_obj_by_depth($t,$depth,$idx)
        $obj  = hwloc_get_obj_by_type($t,$type,$idx)

        $obj  = $t->get_obj_by_depth($depth,$idx)
        $obj  = $t->get_obj_by_type($type,$idx)

=head2 Topology object properties

        $val  = $obj->type
        $val  = $obj->os_index
        $val  = $obj->name
        $href = $obj->memory           since  hwloc 1.0
        $href = $obj->attr             since  hwloc 1.0
        $val  = $obj->depth
        $val  = $obj->logical_index
        $val  = $obj->os_level
        $obj  = $obj->next_cousin
        $obj  = $obj->prev_cousin
        $obj  = $obj->father           before hwloc 1.0
        $obj  = $obj->parent           since  hwloc 1.0
        $val  = $obj->sibling_rank
        $obj  = $obj->next_sibling
        $obj  = $obj->prev_sibling
        $val  = $obj->arity
        @objs = $obj->children
        $obj  = $obj->first_child
        $obj  = $obj->last_child
        href  = $obj->infos            since  hwloc 1.1

=head2 Object/string conversion

        $val  = hwloc_obj_type_string($type)
        $val  = hwloc_obj_type_of_string($string)
        $val  = hwloc_obj_type_sprintf($obj,$verbose)             since  hwloc 1.0
        $val  = hwloc_obj_attr_sprintf($obj,$separator,$verbose)  since  hwloc 1.0
        $val  = hwloc_obj_cpuset_sprintf($obj1,$obj2,...)
        $val  = hwloc_obj_sprintf($t,$obj,$prefix,$verbose)
        $val  = hwloc_obj_get_info_by_name($obj,$string)          since  hwloc 1.1

        $val  = $obj->sprintf_type($verbose)                      since  hwloc 1.0
        $val  = $obj->sprintf_attr($separator,$verbose)           since  hwloc 1.0
        $val  = $obj->sprintf_cpuset
        $val  = $t->sprintf_obj($obj,$prefix,$verbose)
        $val  = $obj->info_by_name($string)                       since  hwloc 1.1

=head2 Object type helpers

        $val  = hwloc_get_type_or_below_depth($t,$type)
        $val  = hwloc_get_type_or_above_depth($t,$type)

        $val  = $t->get_type_or_below_depth($type)
        $val  = $t->get_type_or_above_depth($type)

=head2 Basic traversal helpers

        $obj  = hwloc_get_system_obj($t)                        before hwloc 1.0
        $obj  = hwloc_get_root_obj($t)                          since  hwloc 1.0
        $obj  = hwloc_get_ancestor_obj_by_depth($obj,$depth)    since  hwloc 1.0
        $obj  = hwloc_get_ancestor_obj_by_type($obj,$type)      since  hwloc 1.0
        $obj  = hwloc_get_next_obj_by_depth($t,$depth,$obj)
        $obj  = hwloc_get_next_obj_by_type($t,$type,$obj)
        $obj  = hwloc_get_pu_obj_by_os_index($t,$idx)           since hwloc  1.0
        $obj  = hwloc_get_next_child($obj,$childobj)
        $obj  = hwloc_get_common_ancestor_obj($t,$obj1,$obj2)
        $rc   = hwloc_obj_is_in_subtree($t,$obj1,$obj2)

        $obj  = $t->system                                      before hwloc 1.0
        $obj  = $t->root                                        since  hwloc 1.0
        $obj  = $obj->ancestor_by_depth($depth)                 since  hwloc 1.0
        $obj  = $obj->ancestor_by_type($type)                   since  hwloc 1.0
        $obj  = $t->get_next_obj_by_depth($depth,$obj)
        $obj  = $t->get_next_obj_by_type($type,$obj)
        $obj  = $t->get_pu_obj_by_os_index($idx)                since hwloc  1.0
        $obj  = $obj->next_child($childobj)
        $obj  = $t->get_common_ancestor_obj($obj1,$obj2)
        $obj  = $obj->common_ancestor($obj)
        $rc   = $t->obj_is_in_subtree($obj1,$obj2)
        $rc   = $obj->is_in_subtree($obj)

=head1 AUTHOR

Bernd Kallies, E<lt>kallies@zib.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Bernd Kallies

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
