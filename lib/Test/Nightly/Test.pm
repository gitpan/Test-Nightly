package Test::Nightly::Test;

use strict;
use warnings;

use Carp;
use File::Spec;
use Test::Harness;

use Test::Nightly;
use Test::Nightly::Email;

use base qw(Test::Nightly::Base Class::Accessor::Chained::Fast);

my @methods = qw(
    modules
	test_directory_format
	test_file_format 
	tests 
);

__PACKAGE__->mk_accessors(@methods);

our $VERSION = '0.02';

=head1 NAME

Test::Nightly::Test - Make and runs your tests.

=head1 DESCRIPTION

Designed to run our tests, and then store the results back into the object.

=head1 SYNOPSIS

  use Test::Nightly::Test;

  my $test = Test::Nightly::Test->new();

  $test->run();

The following methods are available:

=cut

=head2 new()

  my $test = Test::Nightly::Test->new({
    modules               => \@modules,        # Required.
    test_directory_format => ['t/', 'tests/'], # Optional, defaults to ['t/'].
    test_file_format      => ['.t', '.pl'],    # Optional, defaults to ['.t'].
  });

Create a new Test::Nightly::Test object.

C<modules> is an array of the has refs that include the path to the module and the makefile name. It isn't required that you supply this because the directories are found from the Test::Nightly object. You may want to specify these if you are calling this separately.

C<test_directory_format> in an array ref of what the test directories can be. By default it searches for the tests in ['t/'].

C<test_file_format> is an array ref of the file types that your tests are. Defaults to ['.t'].

=cut

sub new {

    my ($class, $conf) = @_;

	my $self = {};

    bless($self, $class);

	$self->_init($conf, \@methods);
		
	unless ($self->modules()) {

		$self->_add_error('Test::Nightly::Test::new() - "modules" must be supplied');

	} else {

		$self->test_directory_format(['t/']) unless ($self->test_directory_format());
		$self->test_file_format(['.t']) unless ($self->test_file_format());

		return $self;
	
	}

}

=head2 run()

  $test->run({
    # ... can take the same arguments as new() ... 
  });

Loops through the supplied modules, makes those modules and runs their tests.

=cut

sub run {

    my ($self, $conf) = @_;

	if (ref($self->test_directory_format()) !~ /ARRAY/) {
		$self->_add_error('Test::Nightly::Test::run(): Supplied test_directory_format must be an array reference');
		return;
	} elsif (ref($self->test_file_format()) !~ /ARRAY/) {
		$self->_add_error('Test::Nightly::Test::run(): Supplied test_file_format must be an array reference');
		return;
	} 

	my %tests;

	$self->_debug('About to run the tests');

	if (scalar @{$self->modules()}) {

		foreach my $module (@{$self->modules()}) {

			## check if dir exists			
			my $chdir_result = chdir($module->{directory});
			unless ($chdir_result) {
				$self->_add_error('Test::Nightly::Test::run(): Unable to change directory to: '.$module->{directory}.', skipping');
				next;
			}

			$self->_debug('Changed directory to: ' . $module->{directory});

			# There must be a better way to call this - don't know how though!
			$self->_debug('Making ' . $module->{directory});
			`perl $module->{makefile}`;
			`make -s`;

			# Loop through each test_path that has been passed in
			foreach my $test_path (@{$self->test_directory_format()}) {
			
				$self->_debug('Current test path is: ' . $test_path);

				# Loop through each test extention that has been passed in
				foreach my $test_ext (@{$self->test_file_format()}) {

					$self->_debug('Current test extention is: ' . $test_ext);
		
					# Strip out the leading slash just so we won't get a double slash

					my $full_path = File::Spec->canonpath($module->{directory} . $test_path);

					$self->_debug('Full path is: ' . $full_path);

					if(-d $test_path) {
		
						$self->_debug('Looking for tests that match the extention: ' . $test_ext.' in the path: ' . $test_path);
						# Find all the tests for this module

						my @found_tests = File::Find::Rule->file()->name( '*' . $test_ext )->in( $test_path );

						# Run through each test individually, so our report is more specific.
						foreach my $test (@found_tests) {

							# runtests() from Test::Harness
							my $passed = eval{runtests($test)}; # It would be nice if we could suppress the output here. No idea how to do it.
							my %single_test = (
								test => $test,
							);
							
							if ($passed) {
								$single_test{'status'} = 'passed';
							} else {
								$single_test{'status'} = 'failed';
							}

							push (@{$tests{$full_path}}, \%single_test);
							
						}

						# cleanup
						`make -s clean`;

					}

				}

			}

		}

		$self->tests(\%tests);

	}

}

# Extract out only the passed tests from tests()

sub passed_tests {

    my $self = shift;

	my %passed_tests;
	if (defined $self->tests()) {

		foreach my $module (keys %{$self->tests()}) {

			foreach my $tests ($self->tests()->{$module}){

				foreach my $test (@{$tests}) {

					if ($test->{'status'} eq 'passed') {
						push (@{$passed_tests{$module}}, $test);
					}
				}
			}
		}


	} 

	if ( scalar keys %passed_tests ) {
		return \%passed_tests;
	} else {
		return undef;
	}

}

# Extract out only the passed tests from failed_tests()

sub failed_tests {

    my $self = shift;

	my %failed_tests;
	if (defined $self->tests()) {

		foreach my $module (keys %{$self->tests()}) {

			foreach my $tests ($self->tests()->{$module}){

				foreach my $test (@{$tests}) {

					if ($test->{'status'} eq 'failed') {
						push (@{$failed_tests{$module}}, $test);
					}
				}
			}
		}
	} 

	if ( scalar keys %failed_tests ) {
		return \%failed_tests;
	} else {
		return undef;
	}

}


sub DESTROY {

    my ($self) = @_;

    # Can be found in Test::Nightly::Base
    $self->_destroy();

}

=head1 List of methods:

=over 4

=item modules

List of modules. Usually is generated when you call L<Test::Nightly> new method, however it is possible to pass it in directly here. 
Structure is like so:

@modules = (
  {
    'directory' => '/dir/to/module01/'
    'makefile   => 'Makefile.PL'  
  },
  {
    'directory' => '/dir/to/module02/'
    'makefile   => 'Makefile.PL'  
  },
);

=item test_directory_format
  
An array ref of what format the test directories can be. By default it searches for the tests in 't/'.

=item test_file_format 

An array ref of the test file formats you have. e.g. @file_formats = ('.pl', '.t'); Defaults to ['.t'].

=item tests

Where the output is stored after running the tests.

=head1 TODO

Find a way to suppress the output while the tests are running.

=head1 AUTHOR

Kirstin Bettiol <kirstinbettiol@gmail.com>

=head1 COPYRIGHT

(c) 2005 Kirstin Bettiol
This library is free software, you can use it under the same terms as perl itself.

=head1 SEE ALSO

L<Test::Nightly>,
L<Test::Nightly::Test>,
L<Test::Nightly::Report>,
L<Test::Nightly::Email>,
L<Test::Nightly::Version>,
L<Test::Nightly::Coverage>,
L<perl>.

=cut

1;

