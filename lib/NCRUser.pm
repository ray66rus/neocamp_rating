package NCRUser;

use strict;

my $USERS = {
	'admin' => 'secret',
};

sub new { bless {}, shift }

sub check {
	my ($self, $user, $pass) = @_;

	return (defined($USERS->{$user}) and $USERS->{$user} eq $pass) ? 1 : 0
}

1;
