package TSVRPC::Client;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.01';
use TSVRPC::Parser;
use TSVRPC::Util;
use TSVRPC::Response;
use WWW::Curl::Easy;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $base = $args{base} or Carp::croak("missing argument named 'base' for rpc base url");
    $base .= '/' unless $base =~ m{/$};

    my $timeout = exists( $args{timeout} ) ? $args{timeout} : 1;

    my $agent = $args{agent} || "$class/$VERSION";

    my $curl = WWW::Curl::Easy->new();
    $curl->setopt(CURLOPT_TIMEOUT, $timeout);
    $curl->setopt(CURLOPT_USERAGENT, $agent);

    return bless {curl => $curl, base => $base}, $class;
}

sub call {
    my ( $self, $method, $args ) = @_;
    my $req_encoding = 'U';
    my $content      = TSVRPC::Parser::encode_tsvrpc($args, $req_encoding);
    my $curl = $self->{curl};
    $curl->setopt(CURLOPT_URL, $self->{base} . $method);
    $curl->setopt( CURLOPT_HTTPHEADER,
        [
            "Content-Type: text/tab-separated-values; colenc=$req_encoding",
            "Content-Length: " . length($content),
            "Connection: Keep-Alive",
            "Keep-Alive: 300",
            "\r\n"
        ]
    );
    $curl->setopt(CURLOPT_CUSTOMREQUEST, "POST");
    $curl->setopt(CURLOPT_POSTFIELDS, $content);
    $curl->setopt(CURLOPT_HEADER, 0);
    my $response_content = '';
    open(my $fh, ">", \$response_content) or die "cannot open buffer";
    $curl->setopt(CURLOPT_WRITEDATA, $fh);
    my $content_type;
    $curl->setopt( CURLOPT_HEADERFUNCTION,
        sub { $content_type = $1 if $_[0] =~ /^Content-Type\s*:\s*(.+)\015\012$/; return length( $_[0] ); } );
    if ($curl->perform() == 0) {
        my $code = $curl->getinfo(CURLINFO_HTTP_CODE);
        return TSVRPC::Response->new($method, $code, $content_type, $response_content);
    } else {
        die "invalid";
    }
}

1;
__END__

=head1 NAME

TSVRPC::Client - TSV-RPC client library

=head1 SYNOPSIS

    use TSVRPC::Client;

    my $t = TSVRPC::Client->new(
        base    => 'http://localhost:1978/rpc/',
        agent   => "myagent",
        timeout => 1
    );
    $t->call('echo', {a => 'b'});

=head1 DESCRIPTION

The client library for TSV-RPC.

=head1 METHODS

=over 4

=item my $t = TSVRPC::Client->new();

Create new instance.

=over 4

=item base

The base TSV-RPC end point URL.

=item timeout

Timeout value for each request.

I<Default>: 1 second

=item agent

User-Agent value.

=back

=item $t->call($method, \%args);

Call the $method with \%args.

I<Return>: instance of L<TSVRPC::Response>.

=back

=head1 SEE ALSO

L<http://fallabs.com/mikio/tech/promenade.cgi?id=97>

