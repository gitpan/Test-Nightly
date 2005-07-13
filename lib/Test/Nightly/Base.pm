package Test::Nightly::Base;

use strict;
use warnings;

use Carp;

use Test::Nightly::Email;

use base 'Class::Accessor::Chained::Fast';

my @methods = qw(
	debug
	email_errors
	errors
	log_errors
	print_errors
	report_template
);

__PACKAGE__->mk_accessors(@methods);

our $VERSION = '0.02';

=head1 NAME

Test::Nightly::Base - Internal base methods

=head1 DESCRIPTION

Provides internal base methods for the Test::Nightly::* modules

=cut

#
# _init()
#
# Initialises the methods that have been passed in.
#

sub _init {

    my ($self, $conf, $methods) = @_;

	my @all_methods = @{$methods};
	push (@all_methods, @methods);

    my $is_obj = 1 if ref($conf) =~ /Test::Night/;
    foreach my $method (@all_methods) {

        if (defined $conf->{$method}) {
            if($is_obj) {
                $self->$method($conf->$method());
            } else {
                $self->$method($conf->{$method});
            }
        }
    }

}

#
# _add_error()
#
# Compiles a list of errors.
#

sub _add_error {

    my ($self, $error) = @_;

    if (defined $self->errors()) {
        push (@{$self->errors()}, $error);
    } else {
        $self->errors([$error]);
    }

}

#
# _debug()
#
# Carps a debug message.
#

sub _debug {

    my ($self, $msg) = @_;

    if (defined $self->debug()) {
        carp $msg;
    }

}

#
# _destroy()
#
# On DESTROY this method is called to handle the errors.
#

sub _destroy {

    my ($self) = @_;

    if (defined $self->errors()) {

        if (defined $self->log_errors()) {

            open(FH,">".$self->log_errors()) || $self->_error('Test::Nightly::Base::destroy() - Error with "log_errors" ('.$self->log_errors()->{file}.') : '.$!);
            print FH join("\n", @{$self->errors()});
            close(FH);

        }

        if (defined $self->email_errors()) {

            my $email = Test::Nightly::Email->new($self->email_errors());

            $email->email({
                subject => 'Errors created while running Test::Nightly',
                message => join("\n", @{$self->errors()}),
            });

        }

        if (defined $self->print_errors()) {
            print join("\n", @{$self->errors()})."\n";
        }

    }

}

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
L<perl>.

=cut

1;

