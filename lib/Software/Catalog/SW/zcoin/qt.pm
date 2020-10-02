## no critic: ControlStructures::ProhibitMutatingListFunctions

package Software::Catalog::SW::zcoin::qt;

# AUTHORITY
# DATE
# DIST
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

sub archive_info {
    my ($self, %args) = @_;
    [200, "OK", {
        programs => [
            {name=>"zcoin-cli", path=>"/bin"},
            {name=>"zcoin-qt", path=>"/bin"},
            {name=>"zcoind", path=>"/bin"},
        ],
    }];
}

sub available_versions {
    my ($self, %args) = @_;

    my $res = extract_from_url(
        url => "https://github.com/zcoinofficial/zcoin/releases",
        re  => qr!/zcoinofficial/zcoin/tree/([^"/]+)!,
        all => 1,
    );
    return $res unless $res->[0] == 200;
    # sort versions from earliest
    $res->[2] = [ sort { $self->cmp_version($a, $b) }
                      map { s/\Av//; $_ }
                      @{$res->[2]}];
    $res;
}

sub canon2native_arch_map {
    return +{
        'linux-x86_64' => 'linux64',
        'win64' => 'win64',
    },
}

sub download_url {
    my ($self, %args) = @_;

    my $version  = $args{version};
    my $rversion = $args{version};
    if (!$version) {
        my $verres = $self->latest_version(maybe arch => $args{arch});
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

sub homepage_url {"http://zcoin.io/" }

sub is_dedicated_profile { 0 }

sub latest_version {
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

sub release_note {
    require Mojo::DOM;

    my ($self, %args) = @_;
    my $format = $args{format} // 'text';

    my $version = $args{version} // do {
        my $res = $self->latest_version(%args);
        return $res unless $res->[0] == 200;
        $res->[2];
    };

    $version =~ s/\Av//;

    my $url = "https://github.com/zcoinofficial/zcoin/releases/tag/v$version";
    my $res = extract_from_url(
      url => $url,
      code => sub {
          my %cargs = @_;
          my $dom = Mojo::DOM->new($cargs{content});
          my $html = $dom->at(".markdown-body")->content;

          if ($html) {
              if ($format eq 'html') {
                  return [200, "OK", $html];
              } else {
                  require HTML::FormatText::Any;
                  return [200, "OK",
                          HTML::FormatText::Any::html2text(html => $html)->[2]];
              }
          } else {
              return [543, "Cannot scrape release note text from $url"];
          }
      },
  );
}

sub versioning_scheme { "Dotted" }

1;
# ABSTRACT: Zcoin desktop GUI client

=for Pod::Coverage ^(.+)$
