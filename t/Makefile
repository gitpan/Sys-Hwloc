###############################################################################
# Run test suite
#
# $Id: Makefile,v 1.3 2010/12/16 20:38:37 bzbkalli Exp $
###############################################################################

TESTS = 00-use.t \
        01-api.t \
        02-topo.t \
        03-topoinfo.t \
        04-obj.t \
        05-strings.t \
        06-helpers.t \
        07-cpuset.t

all:
	perl -I../blib/lib -I../blib/arch -MTest::Harness -e '$$Test::Harness::verbose=0; runtests @ARGV;' $(TESTS)
verbose:
	perl -I../blib/lib -I../blib/arch -MTest::Harness -e '$$Test::Harness::verbose=1; runtests @ARGV;' $(TESTS)
clean:
	find . -name '*~' -exec rm -f \{\} \;

.PHONY: $(TESTS)

*.t:
	perl -I../blib/lib -I../blib/arch -MTest::Harness -e '$$Test::Harness::verbose=1; runtests @ARGV;' $@

