package Software::Catalog::SW::zcoin::qt;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use PerlX::Maybe;

use Role::Tiny::With;
with 'Versioning::Scheme::Dotted';
with 'Software::Catalog::Role::Software';

use Software::Catalog::Util qw(extract_from_url);

sub meta {
    return {
        homepage_url => "http://zcoin.io/",
        versioning_scheme => "Dotted",
    };
}

sub get_latest_version {
    my ($self, %args) = @_;

    my $res = extract_from_url(
        url => "https://github.com/zcoinofficial/zcoin/releases",
        code => sub {
            my %cargs = @_;
            my $re = qr!/zcoinofficial/zcoin/releases/download/(v?\d+(?:\.\d+)+)/zcoin(?:-qt)?-(\d+(?:\.\d+)+)-linux64\.!;
            log_trace "Matching against %s", $re;
            if ($cargs{content} =~ $re) {
                return [200, "OK", $2, {'func.real_v' => $1}];
            } else {
                return [543, "Can't extract version from URL"];
            }
        },
    );
}

sub canon2native_arch_map {
    return +{
        'linux-x86_64' => 'linux64',
        'win64' => 'win64',
    },
}

# version
# arch
sub get_download_url {
    my ($self, %args) = @_;

    my $version  = $args{version};
    my $rversion = $args{version};
    if (!$version) {
        my $verres = $self->get_latest_version(maybe arch => $args{arch});
        return [500, "Can't get latest version: $verres->[0] - $verres->[1]"]
            unless $verres->[0] == 200;
        $version  = $verres->[2];
        $rversion = $verres->[3]{'func.real_v'};
    }

    my $filename;
    if ($args{arch} =~ /linux/) {
        $filename = "zcoin-$version-" . $self->_canon2native_arch($args{arch}) . ".tar.gz";
    } else {
        $filename = "zcoin-qt-$version-" . $self->_canon2native_arch($args{arch}) . ".exe";
    }

    [200, "OK",
     join(
         "",
         "https://github.com/zcoinofficial/zcoin/releases/download/$rversion/$filename",
     ), {
         'func.version' => $version,
         'func.filename' => $filename,
     }];
}

sub get_archive_info {
    my ($self, %args) = @_;
    [200, "OK", {
        programs => [
            {name=>"zcoin-cli", path=>"/bin"},
            {name=>"zcoin-qt", path=>"/bin"},
            {name=>"zcoind", path=>"/bin"},
        ],
    }];
}

1;
# ABSTRACT: Zcoin desktop GUI client

=for Pod::Coverage ^(.+)$
