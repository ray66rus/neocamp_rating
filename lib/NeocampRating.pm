package NeocampRating;
use Mojo::Base 'Mojolicious';
use FindBin;

use NCRUser;
use Schema;

has schema => sub {
	return Schema->connect('dbi:SQLite:' . ($ENV{DB_FILE_PATH} || "$FindBin::Bin/../db") . "/main.db");
};

sub startup {
	my $self = shift;

	$self->helper(db => sub { $self->app->schema });
	my $dbh = $self->app->schema->storage->dbh;
	$dbh->{sqlite_unicode} = 1;

	$self->secrets(['bang bang and production']);
	$self->helper(users => sub { state $user = NCRUser->new });

	# Router
	my $r = $self->routes;

	# Normal route to controller
	$r->any('/')->to('students#paged')->name('students');
	$r->any('/all')->to('students#all');
	$r->get('/login')->to('login#login_form');
	$r->post('/login')->to('login#login');
	my $logged_in = $r->under->to('login#logged_in');
	$logged_in->get('/admin')->to('admin#main')->name('admin');
	$logged_in->post('/save_ratings')->to('students#save_ratings');
	$logged_in->get('/load_csv')->to('admin#load_csv_form');
	$logged_in->post('/load_csv')->to('admin#parse_and_save_csv');
	my $student_action = $logged_in->any('/student')->to(controller => 'students');
	$student_action->get('/edit/:id')->to(action => 'edit');
	$student_action->get('/delete/:id')->to(action => 'del');
	$student_action->get('/add')->to(action => 'add');
	$student_action->post('/add')->to(action => 'save');
	$student_action->post('/edit/:id')->to(action => 'save');
	$r->get('/logout')->to('login#logout');
}

1;
