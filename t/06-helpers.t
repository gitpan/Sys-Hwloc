# -----------------------------------------------------------------------------
# Test helpers with topology on this machine
#
# $Id: 06-helpers.t,v 1.6 2010/12/14 18:41:55 bzbkalli Exp $
# -----------------------------------------------------------------------------

use Test::More 0.94;
use strict;
use Sys::Hwloc;

my $apiVersion = HWLOC_API_VERSION();
my $proc_t     = $apiVersion ? HWLOC_OBJ_PU() : HWLOC_OBJ_PROC();
my ($t, $o, $root, $rc, $nobjs, $depth, $test);

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

plan tests => 14;

# --
# Check hwloc_compare_types
# --

my %obj_types = ();
foreach(
	HWLOC_OBJ_CACHE(),
	HWLOC_OBJ_CORE(),
	HWLOC_OBJ_MACHINE(),
	HWLOC_OBJ_MISC(),
	HWLOC_OBJ_NODE(),
	HWLOC_OBJ_SOCKET(),
	HWLOC_OBJ_SYSTEM(),
	$proc_t,
       ) {
  $obj_types{$_} = '';
}
if($apiVersion) {
  $obj_types{HWLOC_OBJ_GROUP()} = '';
}

subtest 'hwloc_compare_types()' => sub {

  plan tests => (scalar keys %obj_types) + 2;

  foreach(sort { $a <=> $b } keys %obj_types) {
    $test = sprintf("hwloc_compare_types(%d,%d)", $_, $_);
    is(hwloc_compare_types($_,$_), 0, $test);
  }

  cmp_ok(hwloc_compare_types($proc_t, HWLOC_OBJ_MACHINE), '>', 0, sprintf("hwloc_compare_types(%d,%d)", $proc_t, HWLOC_OBJ_MACHINE));
  cmp_ok(hwloc_compare_types(HWLOC_OBJ_MACHINE, $proc_t), '<', 0, sprintf("hwloc_compare_types(%d,%d)", HWLOC_OBJ_MACHINE, $proc_t));

};

# --
# Check hwloc_get_type_or_below_depth
# --

$test = "hwloc_get_type_or_below_depth()";
subtest $test => sub {

  plan tests => 2;

  is(hwloc_get_type_or_below_depth($t, HWLOC_OBJ_MACHINE), 0, "hwloc_get_type_or_below_depth(MACHINE)");
  is(hwloc_get_type_or_below_depth($t, $proc_t), hwloc_get_type_depth($t, $proc_t), "hwloc_get_type_or_below_depth(PROC)");

};

# --
# Check hwloc_get_type_or_above_depth
# --

$test = "hwloc_get_type_or_above_depth()";
subtest $test => sub {

  plan tests => 2;

  is(hwloc_get_type_or_above_depth($t, HWLOC_OBJ_MACHINE), 0, "hwloc_get_type_or_above_depth(MACHINE)");
  is(hwloc_get_type_or_above_depth($t, $proc_t), hwloc_get_type_depth($t, $proc_t), "hwloc_get_type_or_above_depth(PROC)");

};

# --
# Check hwloc_get_system_obj
# --

$test = (! $apiVersion) ? "hwloc_get_system_obj()" : "hwloc_get_root_obj()";
subtest $test => sub {

  plan tests => 6;

  if(! $apiVersion) {
    $rc = hwloc_get_system_obj($t);
  } else {
    $rc = hwloc_get_root_obj($t);
  }

  if(isa_ok($rc, 'Sys::Hwloc::Obj', $test)) {
    if(! $apiVersion) {
      is($rc->type, HWLOC_OBJ_SYSTEM, $test."->type");
    } else {
      is($rc->type, HWLOC_OBJ_MACHINE, $test."->type");
    }
    if(is($rc->depth, 0, $test."->depth")) {
      $root = $rc;
    }
  } else {
    fail("\%{$test}");
  }

  if(! $apiVersion) {
    $test = (! $apiVersion) ? "t->system" : "t->root";
    $rc = $t->system;
  } else {
    $rc = $t->root;
  }

  if(isa_ok($rc, 'Sys::Hwloc::Obj', $test)) {
    if(! $apiVersion) {
      is($rc->type, HWLOC_OBJ_SYSTEM, $test."->type");
    } else {
      is($rc->type, HWLOC_OBJ_MACHINE, $test."->type");
    }
    is($rc->depth, 0, $test."->depth");
  } else {
    fail("\%{$test}");
  }

};

# --
# Check hwloc_get_ancestor_obj_by_depth
# --

$test = "hwloc_get_ancestor_obj_by_depth()";
SKIP: {

  skip $test, 2 unless $apiVersion;

  $o = hwloc_get_obj_by_type($t, $proc_t, 0);
  if(isa_ok($o, 'Sys::Hwloc::Obj', sprintf("hwloc_get_obj_by_type(%d,%d)", $proc_t, 0))) {
    subtest $test => sub {

      plan tests => $o->depth * 2;

      my $parent = (! $apiVersion) ? $o->father : $o->parent;

      for(my $i = $o->depth - 1; $i >= 0; $i--) {
	$test = sprintf("hwloc_get_ancestor_obj_by_depth(<proc>,%d)", $i);
	$rc = hwloc_get_ancestor_obj_by_depth($o,$i);
	if(isa_ok($rc, 'Sys::Hwloc::Obj', $test)) {
	  subtest "\%{$test}" => sub {
	    plan tests => 3;
	    is($rc->depth,         $i,                     $test."->depth");
	    is($rc->type,          $parent->type,          $test."->type");
	    is($rc->logical_index, $parent->logical_index, $test."->logical_index");
	  };
	  $parent = (! $apiVersion) ? $rc->father : $rc->parent;
	} else {
	  fail("\%{$test}");
	}
      }

    };
  } else {
    fail($test);
  }

};

# --
# Check hwloc_get_ancestor_obj_by_type
# --

$test = "hwloc_get_ancestor_obj_by_type()";
SKIP: {

  skip $test, 2 unless $apiVersion;

  $o = hwloc_get_obj_by_type($t, $proc_t, 0);
  if(isa_ok($o, 'Sys::Hwloc::Obj', sprintf("hwloc_get_obj_by_type(%d,%d)", $proc_t, 0))) {
    subtest $test => sub {

      plan tests => (scalar keys %obj_types) * 2;

      foreach my $type (reverse sort { $a <=> $b } keys %obj_types) {
	$test = sprintf("hwloc_get_ancestor_obj_by_type(<proc>,%d)", $type);
	$rc = hwloc_get_ancestor_obj_by_type($o,$type);
	if(($type != $o->type) && hwloc_get_nbobjs_by_type($t,$type)) {
	  if(isa_ok($rc, "Sys::Hwloc::Obj", $test)) {
	    subtest "\%{$test}" => sub {
	      plan tests => 2;
	      is($rc->type,      $type,          $test."->type");
	      cmp_ok($rc->depth, '<', $o->depth, $test."->depth");
	    };
	  } else {
	    fail("\%{$test}");
	  }
	} else {
	  if(is($rc, undef, $test)) {
	    pass("\%{$test}");
	  } else {
	    fail("\%{$test}");
	  }
	}
      }

    };
  } else {
    fail($test);
  }

};

# --
# Check hwloc_get_next_obj_by_depth on PROC objects
# --

$depth = $t->depth;
$nobjs = $depth ? $t->get_nbobjs_by_depth($depth-1) : 0;

$test = "hwloc_get_next_obj_by_depth()";
SKIP: {

  skip $test, 1 unless ($depth && $nobjs);
  subtest $test => sub {

    plan tests => $nobjs * 2;

    $o = undef;
    my $i = 0;
    while($o = $t->get_next_obj_by_depth($depth-1, $o)) {
      $test = sprintf("hwloc_get_next_obj_by_depth(%d) %d", $depth-1, $i);
      if(isa_ok($o, "Sys::Hwloc::Obj", $test)) {
	subtest "\%{$test}" => sub {
	  plan tests => 3;
	  is($o->type,          $proc_t,  $test."->type");
	  is($o->depth,         $depth-1, $test."->depth");
	  is($o->logical_index, $i,       $test."->logical_index");
	};
      } else {
	fail("\%{$test}");
      }
      $i++;
    }

  };

};

# --
# Check hwloc_get_next_obj_by_type on PROC objects
# --

$test = "hwloc_get_next_obj_by_type()";
SKIP: {

  skip $test, 1 unless ($depth && $nobjs);
  subtest $test => sub {

    plan tests => $nobjs * 2;

    $o = undef;
    my $i = 0;
    while($o = $t->get_next_obj_by_type($proc_t, $o)) {
      $test = sprintf("hwloc_get_next_obj_by_type(%d) %d", $proc_t, $i);
      if(isa_ok($o, "Sys::Hwloc::Obj", $test)) {
	subtest "\%{$test}" => sub {
	  plan tests => 3;
	  is($o->type,          $proc_t,  $test."->type");
	  is($o->depth,         $depth-1, $test."->depth");
	  is($o->logical_index, $i,       $test."->logical_index");
	};
      } else {
	fail("\%{$test}");
      }
      $i++;
    }

  };

};

# --
# Check hwloc_get_pu_obj_by_os_index on PROC objects
# --

$test = "hwloc_get_pu_obj_by_os_index()";
SKIP: {

  skip $test, 1 unless ($apiVersion && $nobjs);

  subtest $test => sub {

    plan tests => $nobjs * 2;

    for(my $i = 0; $i < $nobjs; $i++) {
      $test = sprintf("hwloc_get_pu_obj_by_os_index(%d)", $i);
      $rc = $t->get_pu_obj_by_os_index($i);
      if(isa_ok($rc, "Sys::Hwloc::Obj", $test)) {
	subtest "\%{$test}" => sub {
	  plan tests => 3;
	  is($rc->type, $proc_t,   $test."->type");
	  is($rc->depth, $depth-1, $test."->depth");
	  is($rc->os_index, $i,    $test."->os_index");
	};
      } else {
	fail("\%{$test}");
      }
    }

  };

};

# --
# Check hwloc_get_common_ancestor_obj on PROC objects
# --

$test = "hwloc_get_common_ancestor_obj()";
SKIP: {

  skip $test, 1 unless $nobjs > 1;

  subtest $test => sub {

    plan tests => 2;

    my $o1 = hwloc_get_obj_by_type($t, $proc_t, 0);
    if(isa_ok($o1, 'Sys::Hwloc::Obj', sprintf("hwloc_get_obj_by_type(%d,%d)", $proc_t, 0))) {
      subtest $test => sub {

	plan tests => ($nobjs - 1) * 3;

	for(my $j = 1; $j < $nobjs; $j++) {
	  my $o2 = hwloc_get_obj_by_type($t, $proc_t, $j);
	  if(isa_ok($o2, 'Sys::Hwloc::Obj', sprintf("hwloc_get_obj_by_type(%d,%d)", $proc_t, $j))) {

	    $test = sprintf("hwloc_get_common_ancestor_obj(P%d,P%d)", 0, $j);
	    $o = hwloc_get_common_ancestor_obj($t, $o1, $o2);
	    if(isa_ok($o, 'Sys::Hwloc::Obj', $test)) {
	      subtest "\%{$test}" => sub {

		plan tests => 1;

		cmp_ok($o->depth, '<', $depth-1, $test."->depth");

	      };
	    } else {
	      fail("\%{$test}");
	    }
	  } else {
	    fail($test);
	  }
	}

      };
    } else {
      fail($test);
    }

  };

};

# --
# Check hwloc_obj_is_in_subtree on PROC objects
# --

$test = "hwloc_obj_is_in_subtree()";
SKIP: {

  skip $test, 1 unless ($root && $nobjs);

  subtest $test => sub {

    plan tests => $nobjs * 2;

    for(my $i = 0; $i < $nobjs; $i++) {
      $test = sprintf("hwloc_get_obj_by_type(%d,%d)", $proc_t, $i);
      $o = hwloc_get_obj_by_type($t, $proc_t, $i);
      if(isa_ok($o, 'Sys::Hwloc::Obj', $test)) {
	subtest "hwloc_obj_is_in_subtree(P$i)" => sub {
	  plan tests => 2;
	  subtest sprintf("is_in_subtree(P%d,<root>)",$i) => sub {
	    plan tests => 2;
	    is(hwloc_obj_is_in_subtree($t,$o,$root), 1, sprintf("hwloc_obj_is_in_subtree(P%d,<root>)", $i));
	    is($o->is_in_subtree($root),             1, sprintf("P%d->is_in_subtree(<root>)", $i));
	  };
	  subtest sprintf("is_in_subtree(<root>,P%d)",$i) => sub {
	    plan tests => 2;
	    is(hwloc_obj_is_in_subtree($t,$root,$o), $nobjs == 1 ? 1 : 0, sprintf("hwloc_obj_is_in_subtree(<root>,P%d)", $i));
	    is($root->is_in_subtree($o),             $nobjs == 1 ? 1 : 0, sprintf("<root>->is_in_subtree(P%d)", $i));
	  };
	};
      } else {
	fail($test);
      }
    }

  };

};

# --
# Check hwloc_get_next_child on ALL objects
# --

$nobjs = 0;
for(my $i = 0; $i < $depth; $i++) {
  my $n = hwloc_get_nbobjs_by_depth($t,$i);
  if(! defined $n) {
    printf STDERR "#fail: hwloc_get_nbobjs_by_depth(%d) returns (undef)\n", $i;
    next;
  }
  $nobjs += $n;
}

$test = "hwloc_get_next_child()";
SKIP: {

  skip $test, 1 unless $nobjs;
  subtest $test => sub {

    plan tests => $nobjs * 2;

    for(my $i = 0; $i < $depth; $i++) {
      my $n = hwloc_get_nbobjs_by_depth($t,$i);
      for(my $j = 0; $j < $n; $j++) {
	$o = hwloc_get_obj_by_depth($t,$i,$j);
	if(isa_ok($o, 'Sys::Hwloc::Obj', sprintf("hwloc_get_obj_by_depth(%d,%d)", $i, $j))) {
	  $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->get_next_child()", $i, $j);
	  if($o->arity) {
	    subtest $test => sub {

	      plan tests => $o->arity * 2;

	      $rc   = undef;
	      my $k = 0;
	      while($rc = $o->get_next_child($rc)) {
		$test = sprintf("hwloc_get_obj_by_depth(%d,%d)->get_next_child() %d", $i, $j, $k);
		if(isa_ok($rc, 'Sys::Hwloc::Obj', $test)) {
		  subtest "\%{$test}" => sub {

		    plan tests => 2;

		    is($rc->depth,        $i+1, $test."->depth");
		    is($rc->sibling_rank, $k,   $test."->sibling_rank");

		  };
		} else {
		  fail("\%{$test}");
		}
		$k++;
	      }
	    };
	  } else {
	    is($o->get_next_child(undef), undef, $test);
	  }
	} else {
	  fail(sprintf("hwloc_get_obj_by_depth(%d,%d)", $i, $j));
	}
      }
    }

  };

};

# --
# Destroy topology
# --

hwloc_topology_destroy($t);
