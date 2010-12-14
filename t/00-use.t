# -----------------------------------------------------------------------------
# Test if module can be loaded
#
# $Id: 00-use.t,v 1.3 2010/12/14 18:41:54 bzbkalli Exp $
# -----------------------------------------------------------------------------

use Test::More tests => 4;

BEGIN { use_ok('Sys::Hwloc') };
use strict;

require_ok('Sys::Hwloc') or
  BAIL_OUT("Hwloc module cannot be loaded");

can_ok('Sys::Hwloc', 'HWLOC_API_VERSION') or
  BAIL_OUT("constant HWLOC_API_VERSION not there");

can_ok('Sys::Hwloc', 'HWLOC_HAS_XML') or
  BAIL_OUT("constant HWLOC_HAS_XML not there");

