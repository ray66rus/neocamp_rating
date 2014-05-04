use utf8;
package Schema::Result::Student;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("students");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "rating",
  { data_type => "int", is_nullable => 1 },
  "img",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "link",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "pid",
  { data_type => "varchar", is_nullable => 1, size => 256 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-05-04 17:36:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8HqvWSmZwi3gj0QH7NOoKQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
