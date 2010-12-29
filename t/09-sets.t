################################################################################
#
#  Copyright 2010 Zuse Institute Berlin
#
#  This package and its accompanying libraries is free software; you can
#  redistribute it and/or modify it under the terms of the GPL version 2.0,
#  or the Artistic License 2.0. Refer to LICENSE for the full license text.
#
#  Please send comments to kallies@zib.de
#
################################################################################
#
# Do some high-level tests with cpusets of topology objects
#
# $Id: 09-sets.t,v 1.3 2010/12/29 16:15:21 bzbkalli Exp $
#
################################################################################

use Test::More 0.94;
use strict;
use Sys::Hwloc 0.07 qw(:DEFAULT :cpuset :bitmap);

plan tests => 6;

my $apiVersion = HWLOC_XSAPI_VERSION();
my $proc_t     = $apiVersion ? HWLOC_OBJ_PU() : HWLOC_OBJ_PROC();
my $cpuset_c   = $apiVersion <= 0x00010000 ? 'Sys::Hwloc::Cpuset' : 'Sys::Hwloc::Bitmap';
my ($t, $o, $rc, $root, $rootset, $test, $nobjs);

SKIP: {

  skip "Topology cpusets and nodesets", 6 unless $apiVersion;

  # --
  # Init topology, stop testing if this fails
  # --

  $t = hwloc_topology_init();
  BAIL_OUT("Failed to initialize topology context via hwloc_topology_init()") unless $t;

  # --
  # Load topology, stop testing if this fails
  # --

  $rc = hwloc_topology_load($t);
  BAIL_OUT("Failed to load topology context") if $rc;

  # --
  # Load root object, stop testing if this fails
  # --

  $root = $t->root;
  BAIL_OUT("Failed to load root object") unless $root;

  $rootset = $root->cpuset;
  isa_ok($rootset, $cpuset_c, 'root->cpuset') or
    BAIL_OUT("Cannot base checks on root->cpuset");

  # Check hwloc_topology_get_allowed_cpuset
  $test = "hwloc_topology_get_allowed_cpuset";
  subtest $test => sub {

    plan tests => 4;

    $rc = hwloc_topology_get_allowed_cpuset($t);
    isa_ok($rc, $cpuset_c, $test);
    is($rootset->isequal($rc),1, "$test eq root->cpuset");

    $rc = $t->get_allowed_cpuset;
    isa_ok($rc, $cpuset_c, "t->get_allowed_cpuset");
    is($rootset->isequal($rc),1, "t->get_allowed_cpuset eq root->cpuset");

  };

  # Walk through PU, see if their cpusets contain their os_index,
  # are contained in root, and do not overlap

  $nobjs = $t->get_nbobjs_by_type($proc_t);

 SKIP: {

    skip "System contains no PU", 1 unless $nobjs;

    subtest "puobj->cpusets" => sub {

      plan tests => $nobjs * 5 + 1;

      my @objs = ();
      $o = undef;
      while($o = $t->get_next_obj_by_type($proc_t, $o)) {
	$test = sprintf("pu[%d]->cpuset", $o->os_index);
	$rc = $o->cpuset;
	push @objs, $o if isa_ok($rc, $cpuset_c, $test);
	my @ids = $rc->ids;
	is(scalar @ids, 1, "$test has exactly one bit set");
	ok($rc->isset($o->os_index), "$test has os_index set");
	ok($rootset->includes($rc), "rootset includes $test");

	if($o->prev_sibling) {
	  is($o->cpuset->intersects($o->prev_sibling->cpuset), 0, "$test does not intersect with prev_sibling");
	} else {
	  pass("$test intersects with prev_sibling");
	}
      }

      # generate string containing all PU sets,
      # should be equal to stringified root cpuset
      is(hwloc_obj_cpuset_sprintf(@objs), $rootset->sprintf, "joined PU sets stringify to rootset");

    }

  };

 SKIP: {

    skip "Topology nodesets", 3 unless $apiVersion >= 0x00010100;

    $rootset = $root->allowed_nodeset;
    isa_ok($rootset, $cpuset_c, 'root->nodeset') or
      BAIL_OUT("Cannot base checks on root->nodeset");

    # Check hwloc_topology_get_allowed_nodeset
    $test = "hwloc_topology_get_allowed_nodeset";
    subtest $test => sub {

      plan tests => 4;

      $rc = hwloc_topology_get_allowed_nodeset($t);
      isa_ok($rc, $cpuset_c, $test);
      is($rootset->isequal($rc),1, "$test eq root->nodeset");

      $rc = $t->get_allowed_nodeset;
      isa_ok($rc, $cpuset_c, "t->get_allowed_nodeset");
      is($rootset->isequal($rc),1, "t->get_allowed_nodeset eq root->nodeset");

    };

    # Walk through PU, see if their cpusets contain their os_index,
    # are contained in root, and do not overlap

    $nobjs = $t->get_nbobjs_by_type(HWLOC_OBJ_NODE);

    if($nobjs) {

      subtest "nodeobj->nodesets" => sub {

	plan tests => $nobjs * 5 + 1;

	my $set = Sys::Hwloc::Bitmap->new;

	$o = undef;
	while($o = $t->get_next_obj_by_type(HWLOC_OBJ_NODE, $o)) {
	  $test = sprintf("node[%d]->nodeset", $o->os_index);
	  $rc = $o->nodeset;
	  $set->or($rc) if isa_ok($rc, $cpuset_c, $test);
	  my @ids = $rc->ids;
	  is(scalar @ids, 1, "$test has exactly one bit set");
	  ok($rc->isset($o->os_index), "$test has os_index set");
	  ok($rootset->includes($rc), "rootset includes $test");

	  if($o->prev_sibling) {
	    is($o->nodeset->intersects($o->prev_sibling->nodeset), 0, "$test does not intersect with prev_sibling");
	  } else {
	    pass("$test intersects with prev_sibling");
	  }
	}

	# generate string containing all NODE sets,
	# should be equal to stringified root nodeset
	is($set->sprintf, $rootset->sprintf, "ORed NODE sets stringify to rootset");

	$set->free;

      };

    } else {

      ok($rootset->isfull, "root->nodeset should be infinite");

    }

  };

};
