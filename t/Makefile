###############################################################################
# Run test suite
#
# $Id: Makefile,v 1.1 2010/12/09 21:48:24 bzbkalli Exp $
###############################################################################

all:
	perl -I../blib/lib -I../blib/arch -MTest::Harness -e '$$Test::Harness::verbose=0; runtests @ARGV;' *.t
verbose:
	perl -I../blib/lib -I../blib/arch -MTest::Harness -e '$$Test::Harness::verbose=1; runtests @ARGV;' *.t
clean:
	find . -name '*~' -exec rm -f \{\} \;
