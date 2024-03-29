package KyotoTycoon::Cursor;
use strict;
use warnings;

# Do not call this method manually.
sub new {
    my ($class, $cursor_id, $db, $client) = @_;
    bless { db => $db, client => $client, cursor => $cursor_id }, $class;
}

sub jump {
    my ($self, $key) = @_;
    my %args = (DB => $self->{db}, CUR => $self->{cursor});
    $args{key} = $key if defined $key;
    my $res = $self->{client}->call('cur_jump', \%args);
    return 1 if $res->code eq 200;
    return 0 if $res->code eq 450;
    die $res->status_line;
}

sub jump_back {
    my ($self, $key) = @_;
    my %args = (DB => $self->{db}, CUR => $self->{cursor});
    $args{key} = $key if defined $key;
    my $res = $self->{client}->call('cur_jump_back', \%args);
    return 1 if $res->code eq 200;
    return 0 if $res->code eq 450;
    die $res->status_line;
}

sub step {
    my ($self, ) = @_;
    my %args = (CUR => $self->{cursor});
    my $res = $self->{client}->call('cur_step', \%args);
    return 1 if $res->code eq '200';
    return 0 if $res->code eq '450';
    die $res->status_line;
}

sub step_back {
    my ($self, ) = @_;
    my %args = (CUR => $self->{cursor});
    my $res = $self->{client}->call('cur_step_back', \%args);
    return 1 if $res->code eq '200';
    return 0 if $res->code eq '450';
    die $res->status_line;
}

sub set_value {
    my ($self, $value, $xt, $step) = @_;
    my %args = (CUR => $self->{cursor}, value => $value);
    $args{xt} = $xt if defined $xt;
    $args{step} = '' if defined $step;
    my $res = $self->{client}->call('cur_set_value', \%args);
    return 1 if $res->code eq '200';
    return 0 if $res->code eq '450';
    die $res->status_line;
}

sub remove {
    my ($self,) = @_;
    my %args = (CUR => $self->{cursor});
    my $res = $self->{client}->call('cur_remove', \%args);
    return 1 if $res->code eq '200';
    return 0 if $res->code eq '450';
    die $res->status_line;
}

sub get_key {
    my ($self, $step) = @_;
    my %args = (CUR => $self->{cursor});
    $args{step} = '' if defined $step;
    my $res = $self->{client}->call('cur_get_key', \%args);
    return $res->body->{key} if $res->code eq '200';
    return if $res->code eq '450';
    die $res->status_line;
}

sub get_value {
    my ($self, $step) = @_;
    my %args = (CUR => $self->{cursor});
    $args{step} = '' if defined $step;
    my $res = $self->{client}->call('cur_get_value', \%args);
    return $res->body->{value} if $res->code eq '200';
    return if $res->code eq '450';
    die $res->status_line;
}

sub get {
    my ($self, $step) = @_;
    my %args = (CUR => $self->{cursor});
    $args{step} = '' if defined $step;
    my $res = $self->{client}->call('cur_get', \%args);
    return ($res->body->{key}, $res->body->{value}) if $res->code eq '200';
    return if $res->code eq '450';
    die $res->status_line;
}

sub delete {
    my ($self, ) = @_;
    my %args = (CUR => $self->{cursor});
    my $res = $self->{client}->call('cur_delete', \%args);
    return if $res->code eq '200';
    die $res->status_line;
}

1;
__END__

=head1 NAME

KyotoTycoon::Cursor - Cursor class for KyotoTycoon

=head1 SYNOPSIS

    my $kt = KyotoTycoon->new(...);
    my $cursor = $kt->make_cursor(1);
    $cursor->jump();
    while (my ($k, $v) = $cursor->get(1)) {
        print "$k: $v";
    }
    $cursor->delete;

=head1 METHODS

=over 4

=item $kt->jump([$key]);

Jump the cursor.

I<$key>: destination record of the jump. The first key if missing.

I<Return>: not useful

=item $kt->jump_back([$key]);

Jump back the cursor. This method is only available on TreeDB.

I<$key>: destination record of the jump. The first key if missing.

I<Return>: 1 if succeeded, 0 if the record is not exists.

I<Exception>: die if /rpc/jump_back is not implemented.

=item $kt->step();

Move cursor to next record.

I<Return>: 1 if succeeded, 0 if the next record is not exists.

=item $kt->step_back()

Step the cursor to the previous record.

I<Return>: 1 on success, or 0 on failure.

=item $kt->set_value($xt, $step);

Set the value of the current record.

I<$value>  the value.

I<$xt>  the expiration time from now in seconds. If it is negative, the absolute value is treated as the epoch time.

I<$step>    true to move the cursor to the next record, or false for no move.

I<Return>: 1 on success, or 0 on failure.

=item $kt->remove();

Remove the current record. 

I<Return>: 1 on success, or 0 on failure.

=item my $key = $kt->get_key([$step])

Get the key of the current record. 

I<$step>: true to move the cursor to the next record, or false for no move.

I<Return>: key on success, or undef on failure.

=item my $value = $kt->get_value([$step]);

Get the value of the current record. 

I<$step>: true to move the cursor to the next record, or false for no move.

I<Return>: value on success, or undef on failure.

=item my ($key, $value) = $kt->get([$step]);

Get a pair of the key and the value of the current record. 

I<$step>: true to move the cursor to the next record, or false for no move.

I<Return>: pair of key and value on success, or empty list on failure.

=item $kt->delete();

Delete the cursor immidiately.

I<Return>: not useful.

=back

