###############################################################################
# Makefile for perl wrapper around hwloc API
#
# $Id: Makefile.PL,v 1.10 2010/12/14 18:41:54 bzbkalli Exp $
###############################################################################

use ExtUtils::MakeMaker;
use Config;

%INFOS   = (
	    NAME              => 'Sys::Hwloc',
	    VERSION_FROM      => 'lib/Sys/Hwloc.pm',
	    AUTHOR            => 'Bernd Kallies <kallies@zib.de>',
	    ABSTRACT          => 'Perl wrapper around the hwloc API',
	    PREREQ_PM         => {
				   'Test::More' => '0.89',
				 },
	   );

# --
# Configure using pkg-config
# --

%CONFIGS = (
	    config            => {
				  'prefix'      => undef,
				  'exec_prefix' => undef,
				  'bindir'      => undef,
				  'libdir'      => undef,
				  'includedir'  => undef,
				  'iflags'      => undef,
				  'libs'        => undef,
				 },
	    HWLOC_API_VERSION => undef,
	    HWLOC_HAS_XML     => 0,
	   );

configure();

# --
# Write makefile
# --

WriteMakefile(
 	      %INFOS,
 	      INC       => "$CONFIGS{config}->{iflags}",
              OPTIMIZE  => "$Config{optimize} -Wno-unused",
 	      LDDLFLAGS => "$Config{lddlflags} $CONFIGS{config}->{libs}",
	      PM_FILTER => "sed -e s/\@HWLOC_API_VERSION\@/$CONFIGS{HWLOC_API_VERSION}/",
 	     );

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (
	       { name => 'HWLOC_OBJ_SYSTEM',                  macro => 1 },
	       { name => 'HWLOC_OBJ_MACHINE',                 macro => 1 },
	       { name => 'HWLOC_OBJ_NODE',                    macro => 1 },
	       { name => 'HWLOC_OBJ_SOCKET',                  macro => 1 },
	       { name => 'HWLOC_OBJ_CACHE',                   macro => 1 },
	       { name => 'HWLOC_OBJ_CORE',                    macro => 1 },
	       { name => 'HWLOC_OBJ_MISC',                    macro => 1 },
	       { name => 'HWLOC_TOPOLOGY_FLAG_IS_THISSYSTEM', macro => 1 },
	       { name => 'HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM',  macro => 1 },
	       { name => 'HWLOC_TYPE_DEPTH_MULTIPLE',         macro => 1 },
	       { name => 'HWLOC_TYPE_DEPTH_UNKNOWN',          macro => 1 },
	       { name => 'HWLOC_TYPE_UNORDERED',              macro => 1 },
	       { name => 'HWLOC_HAS_XML',                     macro => 1 },
	      );

  if(! $CONFIGS{HWLOC_API_VERSION}) {
    push @names, { name => 'HWLOC_OBJ_PROC',    macro => 1 };
  } else {
    push @names, { name => 'HWLOC_OBJ_GROUP',   macro => 1 };
    push @names, { name => 'HWLOC_OBJ_PU',      macro => 1 };
  }

  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Sys::Hwloc',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

} else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

sub configure {

  print "checking for hwloc... ";
  my $output = `pkg-config --exists --print-errors hwloc 2>&1`;
  if($?) {
    die "no\n$output";
  } else {
    print "yes\n";
  }

  print "checking for hwloc prefix... ";
  $CONFIGS{config}->{prefix} = pkg_config_get("variable=prefix");
  print "$CONFIGS{config}->{prefix}\n";

  print "checking for hwloc eprefix... ";
  $CONFIGS{config}->{eprefix} = pkg_config_get("variable=exec_prefix");
  print "$CONFIGS{config}->{eprefix}\n";

  print "checking for hwloc bindir... ";
  $CONFIGS{config}->{bindir}  = pkg_config_get("variable=bindir");
  $CONFIGS{config}->{bindir}  = "$CONFIGS{config}->{eprefix}/bin" if(! $CONFIGS{config}->{bindir} && $CONFIGS{config}->{eprefix});
  $CONFIGS{config}->{bindir}  = "$CONFIGS{config}->{prefix}/bin"  if(! $CONFIGS{config}->{bindir} && $CONFIGS{config}->{prefix});
  print "$CONFIGS{config}->{bindir}\n";

  print "checking for hwloc libdir... ";
  $CONFIGS{config}->{libdir}  = pkg_config_get("variable=libdir");
  $CONFIGS{config}->{libdir}  = "$CONFIGS{config}->{eprefix}/lib" if(! $CONFIGS{config}->{libdir} && $CONFIGS{config}->{eprefix});
  $CONFIGS{config}->{libdir}  = "$CONFIGS{config}->{prefix}/lib"  if(! $CONFIGS{config}->{libdir} && $CONFIGS{config}->{prefix});
  print "$CONFIGS{config}->{libdir}\n";

  print "checking for hwloc includedir... ";
  $CONFIGS{config}->{includedir} = pkg_config_get("variable=includedir");
  $CONFIGS{config}->{includedir} = "$CONFIGS{config}->{eprefix}/include" if(! $CONFIGS{config}->{includedir} && $CONFIGS{config}->{eprefix});
  $CONFIGS{config}->{includedir} = "$CONFIGS{config}->{prefix}/include"  if(! $CONFIGS{config}->{includedir} && $CONFIGS{config}->{prefix});
  print "$CONFIGS{config}->{includedir}\n";

  print "checking for hwloc -I flags... ";
  $CONFIGS{config}->{iflags} = pkg_config_get("cflags-only-I");
  print "$CONFIGS{config}->{iflags}\n";

  print "checking for hwloc linker flags... ";
  $CONFIGS{config}->{libs} = pkg_config_get("libs");
  $CONFIGS{config}->{libs} = "-Wl,-rpath,$CONFIGS{config}->{libdir} $CONFIGS{config}->{libs}" if $CONFIGS{config}->{libdir};
  print "$CONFIGS{config}->{libs}\n";

  print "checking HWLOC_API_VERSION... ";
  my $cmd = "echo HWLOC_API_VERSION | cpp -w -P -include hwloc.h";
  $cmd   .= " -I$CONFIGS{config}->{includedir}" if $CONFIGS{config}->{includedir};
  $output  = `$cmd`;
  if($?) {
    die "Failed to determine HWLOC_API_VERSION\n";
  } else {
    (my $lastword) = ($output =~ /(\S+)$/);
    die "\nFailed to determine HWLOC_API_VERSION\n" unless defined $lastword;
    if($lastword ne "HWLOC_API_VERSION") {
      $CONFIGS{HWLOC_API_VERSION} = $lastword;
      print "$CONFIGS{HWLOC_API_VERSION}\n";
    } else {
      print "(undef)\n";
    }
  }

  print "checking if hwloc supports XML... ";
  $cmd     = "lstopo /tmp/topo.xml";
  $cmd     = "$CONFIGS{config}->{bindir}/$cmd" if $CONFIGS{config}->{bindir};
  $output  = `$cmd 2>&1`;
  if($?) {
    print "apparently no\n";
  } else {
    print "yes\n";
    $CONFIGS{HWLOC_HAS_XML} = 1;
  }
  $CONFIGS{config}->{iflags} .= " -DHWLOC_HAS_XML=$CONFIGS{HWLOC_HAS_XML}";
  `rm -f /tmp/topo.xml`;

}

sub pkg_config_get {
  my $what = shift;
  my $cmd  = "pkg-config --$what hwloc";
  my $data = `$cmd`;
  die "$cmd failed.\n" if $?;
  $data =~ s/[\015\012]+$//;
  return $data;
}
