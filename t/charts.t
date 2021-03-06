BEGIN { $ENV{PASTE_ENABLE_CHARTS} = 1 }
use t::Helper;
use Mojo::JSON 'true';

my $t = t::Helper->t;
my ($raw, $file, $json);

plan skip_all => "$ENV{PASTE_DIR} was not created" unless -d $ENV{PASTE_DIR};

$raw = <<"HERE";

#
# Some cool header
#
# A wonderful description.
#

Date,Down,Up
2015-02-04 15:03,120,90
2015-03-14,75,65

# this is a bit weird...?
2015-04,100,40

#
HERE
$t->post_ok('/', form => {paste => $raw, p => 1})->status_is(302);
$file = $t->tx->res->headers->location =~ m!/(\w+)$! ? $1 : 'nope';

$t->get_ok("/$file/chart")->status_is(200)->content_like(qr{jquery\.min\.js})->content_like(qr{morris\.css})
  ->content_like(qr{morris\.min\.js})->content_like(qr{raphael-min\.js})->element_exists('div[id="chart"]')
  ->element_exists('nav')->text_like('h2', qr{Some cool header}, 'header')
  ->text_like('p', qr{A wonderful description\.}, 'description');

$json = $t->tx->res->body =~ m!new Morris\.Line\(([^\)]+)\)! ? Mojo::JSON::decode_json($1) : undef;
is_deeply(
  $json,
  {
    element   => 'chart',
    hideHover => true,
    resize    => true,
    labels    => [qw(Down Up)],
    ykeys     => [qw(Down Up)],
    xkey      => 'Date',
    data      => [
      {Date => '2015-02-04 15:03', Down => 120, Up => 90},
      {Date => '2015-03-14',       Down => 75,  Up => 65},
      {Date => '2015-04',          Down => 100, Up => 40}
    ],
  },
);

unlink glob("$ENV{PASTE_DIR}/*");

done_testing;
