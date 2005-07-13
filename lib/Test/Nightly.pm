package Test::Nightly;

use strict;
use warnings;

our $VERSION = '0.02';

use File::Spec;
use File::Find::Rule;

use Test::Nightly::Test;
use Test::Nightly::Email;
use Test::Nightly::Report;

use base qw(Test::Nightly::Base Class::Accessor::Chained::Fast);

my @methods = qw(
	base_directories
	email_report
	makefile_names
    modules
	report_output
	report_template
    test
	test_directory_format
	test_file_format
	test_report
    version_result
);

__PACKAGE__->mk_accessors(@methods);
my @run_these = qw(version_control run_tests coverage_report generate_report);

=head1 NAME

Test::Nightly - Run your tests, produce a report on the results.

=head1 SYNOPSIS

::: SCENARIO ONE :::

Pass in all the options direct into the constructor.

  use Test::Nightly;

  my $nightly = Test::Nightly->new({
    base_directories => ['/base/dir/from/which/to/search/for/modules/'],
    run_tests     => {},
    generate_report => {
        email_report => {
            to      => 'kirstinbettiol@gmail.com',
        },
        report_output => '/report/output/dir/test_report.html',
    },
    email_errors => {
        to      => 'kirstinbettiol@gmail.com',
    },
    print_errors    => 1,
    debug           => 1,
  });

::: SCENARIO TWO :::

Call each method individually.

  use Test::Nightly;

  my $nightly = Test::Nightly->new();

  $nightly->run_tests();

  $nightly->generate_report({
    email_report => {
  	  to      => 'kirstinbettiol@gmail.com',
    },
    report_output => '/report/output/dir/test_report.html',
  });

=cut

=head1 INTRODUCTION

The idea behind this module is to have one script, most probably a cron job, to run all your tests once a night (or once a week). This module will then produce a report on the whether those tests passed or failed. From this report you can see at a glance what tests are failing.

=cut

=head2 new()

  my $nightly = Test::Nightly->new({
    base_directories => \@directories,           # Required. Array of base directories to search in.
    makefile_names   => [Build.PL, Makefile.PL], # Defaults to Makefile.PL.
    email_errors     => \%email_config,          # If set, errors will be emailed.
    log_errors       => '/path/to/log.txt'       # If set, errors will be outputted to the supplied file. 
    print_errors     => 1                        # If set, errors will be printed to stdout. 
    run_tests        => {
  	test_directory_format => ['t/', 'tests/'], # Optional, defaults to 't/'.
  	test_file_format      => ['.t', '.pl'],    # Optional, defaults to '.t'.
    },
    generate_report => {
  	email_report    => \%email_config,                # Emails the report. See L<Test::Nightly::Email> for config.
  	report_template => '/dir/somewhere/template.txt', # Defaults to internal template.
  	report_output   => '/dir/somewhere/output.txt',   # File to output the report to.
  	test_report     => 'all',                         # 'failed' || 'passed'. Defaults to all.
    },
  });

This is the constructor used to create the main object.

Does a search for all modules on your system, matching the makefile description (C<makefile_names>). You can choose to run all your tests and generate your report directly from this module, by supplying C<run_tests> and C<generate_report>. Or you can simply supply C<base_directories> and it call the other methods separately. 

C<email_errors>, C<log_errors> and C<print_errors> relate to how the errors produced from this module (if there are any) are handled. 

=cut

sub new {

    my ($class, $conf) = @_;

	my $self = {};

    bless($self, $class);

	$self->_init($conf, \@methods);

	if (!defined $self->base_directories()) {
		$self->_add_error('Test::Nightly::new() - "base_directories" must be supplied');
	} else {

		$self->makefile_names(['Makefile.PL']) unless defined $self->makefile_names() and ref($self->makefile_names()) eq 'ARRAY';
		$self->_find_modules();

		# See if any methods should be called from new
		foreach my $run (@run_these) {

			if(defined $conf->{$run}) {
				# user wants to run this one
				$self->$run($conf->{$run});
			}
		}
		return $self;
	}
}

=head2 run_tests()

  $nightly->run_tests({
    modules               => \@modules,         # Optional, default is to use the directories stored in the object.
    test_directory_format => ['t/', 'tests/'],  # Optional, defaults to ['t/'].
    test_file_format      => ['.t', '.pl'],     # Optional, defaults to ['.t'].
  });

Runs all the tests on the directories that are stored in the object.

Results are stored back in the object so they can be reported on.

=cut

sub run_tests {

	my ($self, $conf) = @_;

	$self->_init($conf, \@methods);

	my $test = Test::Nightly::Test->new($self);

	$test->run();

	$self->test($test);
	
}

=head2 generate_report()

  $nightly->generate_report({
    email_report    => \%email_config,                # Emails the report. See L<Test::Nightly::Email> for config options.
    report_template => '/dir/somewhere/template.txt', # Defaults to internal template.
    report_output   => '/dir/somewhere/output.txt',   # File to output the report to.
    test_report     => 'all',                         # 'failed' || 'passed'. Defaults to all.
  });

Based on the methods that have been run, produces a report on these. 

Depending on what you pass in, defines what report is generated. If you pass in an email address to L<email_report> then the report will be
emailed. If you specify an output file to C<report_output> then the report will be outputted to that file. 
If you specify both, then both will be done. 

Default behavior is to use the internal template that is in L<Test::Nightly::Report::Template>, however you can overwrite this with your own template (C<report_template>). Uses Template Toolkit logic.

=cut

sub generate_report {

    my ($self, $conf) = @_;

	$self->_init($conf, \@methods);

	my $report = Test::Nightly::Report->new($self);	

	$report->run();

}

sub _find_modules {

    my ($self, $conf) = @_;

	my @modules;

	foreach my $dir (@{$self->base_directories()}) {

		if (-d $dir) {

			foreach my $file (@{$self->makefile_names()}) {

				my @found_makefiles = File::Find::Rule->file()->name($file)->in($dir);

				foreach my $found_makefile (@found_makefiles) {

					my ($volume,$directory,$makefile) = File::Spec->splitpath( $found_makefile );

					my %module;
					$module{'directory'} = $directory;
					$module{'makefile'} = $makefile;
					
					push(@modules, \%module);

				}

			}

		} else {
			$self->_add_error('Test::Nightly::_find_modules() - directory: "'.$dir.'" is not a valid directory');
		}

	}

    $self->modules(\@modules);

}

sub DESTROY {
	
	my ($self) = @_;

	$self->_destroy();

}

=head1 List of methods:

=over 4

=item base_directories

Required. Array ref of base directories to search in.

=item debug

Turns debugging messages on or off.

=item email_errors

If on emails any errors generated. Takes a hash ref of \%email_config, refer to Test::Nightly::Email for the options.

=item email_report

If set will email the report. Takes a hash ref of \%email_config, refer to Test::Nightly::Email for the options.

=item errors

List of errors that have been generated.

=item log_errors

If set, will log any errors generated to the file specified.

=item makefile_names

Searches for the specified makefile names. Defaults to Makefile.PL

=item modules

List of modules that have been found, returns an array ref of undef.

=item print_errors

If set, will print the error to stdout.

=item report_output

Set this to a file somewhere and the report will be outputted here.

=item report_template

Pass this in if you wish to use your own customised report template. Otherwise uses the default template is in Test::Nightly::Report::Template

=item test

Holds the Test::Nightly::Test object.

=item test_directory_format

An array of what format the test directories can be. By default it searches for the tests in 't/'

=item test_file_format

An array of the test file formats you have.

=item test_report

This is where you specify what you wish to report on after the outcome of the test. Specifying 'passed' will only report on tests that passed, specifying 'failed' will only report on tests that failed and specifying 'all' will report on both.

=back

=head1 TODO

Soon I would like to implement a module that will handle version control, so you are able to checkout and update your modules for testing. As well as this it would be nice to incorporate in a wrapper for L<Devel::Cover>.

L<Test::Nightly::Version>,
L<Test::Nightly::Coverage>.

=head1 AUTHOR

Kirstin Bettiol <kirstinbettiol@gmail.com>

=head1 SEE ALSO

L<Test::Nightly>, 
L<Test::Nightly::Test>, 
L<Test::Nightly::Report>, 
L<Test::Nightly::Email>, 
L<perl>.

=head1 COPYRIGHT

(c) 2005 Kirstin Bettiol
This library is free software, you can use it under the same terms as perl itself.

=head1 THANKS

Thanks to Leo Lapworth <LLAP@cuckoo.org> for helping me with this and Foxtons for letting me develop this on their time.

=cut

1;

