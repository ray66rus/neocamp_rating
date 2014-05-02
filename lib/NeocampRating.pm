package NeocampRating;
use Mojo::Base 'Mojolicious';
use FindBin;

use NCRUser;
use Schema;

has schema => sub {
	return Schema->connect('dbi:SQLite:' . ($ENV{DB_FILE_NAME} || "$FindBin::Bin/../db/main.db"));
};

sub startup {
	my $self = shift;

	$self->helper(db => sub { $self->app->schema });

	$self->secrets(['bang bang and production']);
	$self->helper(users => sub { state $user = NCRUser->new });

	# Router
	my $r = $self->routes;

	# Normal route to controller
	$r->any('/')->to('students#main')->name('students');
	$r->get('/login')->to('login#login_form');
	$r->post('/login')->to('login#login');
	my $logged_in = $r->under->to('login#logged_in');
	$logged_in->get('/protected')->to('login#protected');
	$logged_in->post('/save_ratings')->to('students#save_ratings');
	$r->get('/logout')->to('login#logout');
}

1;
