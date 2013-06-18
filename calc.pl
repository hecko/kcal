#!/usr/bin/perl

# This calculator is based on the equations (shown below) derived by LR Keytel, JH Goedecke,
# TD Noakes, H Hiiloskorpi, R Laukkanen, L van der Merwe, and EV Lambert for their study
# titled "Prediction of energy expenditure from heart rate monitoring during submaximal exercise."
#
# calculate HR for weight loss and cardio
# http://www.heart.com/heart-rate-chart.html

use common::sense;
use strict;
use warnings;
#use Data::Dumper::Concise;
use File::Slurp;
use JSON::XS;
use LWP::Simple;
use Mozilla::CA;

my $json = decode_json get('https://raw.github.com/hecko/kcal/master/data/m.json');

my @www_data;

$json->{max_hr}     = max_hr($json);
$json->{cond_hr}    = cond_hr($json);
$json->{aerobic_hr} = aerobic_hr($json);
$json->{wl_hr}      = wl_hr($json);

say "Max HR:                             ".int $json->{max_hr};
say "Ideal HR for fitness conditioning:  ".int $json->{cond_hr};
say "Ideal HR for aerobic/stamina/endur: ".int $json->{aerobic_hr};
say "Ideal HR for weight loss:           ".int $json->{wl_hr};
say "One BMI point:                      ".sprintf ("%.1f", $json->{height}*$json->{height}/10000)." kg";

say "----------";

foreach my $line (@{$json->{data}}) {
    # if we have a more recent value for weight, set that one as default
    # if we do not have any value for weight, set default as current weight
    if ($line->{weight}) {
        $json->{weight} = $line->{weight};
    } else {
        $line->{weight} = $json->{weight};
    };

    $line->{height} ||= $json->{height}; # if not set, get the default

    my $data = {
            weight => $line->{weight},
            height => $json->{height},
            hr => $line->{hr_avg},
            duration => $line->{duration},
            age => $json->{age},
            gender => $json->{gender},
        };

    my $kcal = kcal($data) or next;
    my $bmi  = bmi($data);

    say $line->{date}.": ".(int $kcal)." kcal; ".(sprintf ("%.2f", $bmi))." bmi; ".
        "avg hr: ".$line->{hr_avg}."; ".$line->{weight}."kg; ".$line->{note};

    push @www_data, { date => $line->{date},
                      kcal => $kcal,
                      kg   => $line->{weight},
                      bmi  => $bmi } if $kcal != 0;
};

my $www_data_json = encode_json \@www_data;
write_file('www/data/m.json', $www_data_json);

sub bmi {
  my $kg  = $_[0]->{weight};
  my $m   = $_[0]->{height} / 100;
  my $bmi = $kg / ($m * $m);
  return $bmi;
}

sub kcal {
    my $kg  = $_[0]->{weight};
    my $hr  = $_[0]->{hr};
    my $dur = $_[0]->{duration};
    my $age = $_[0]->{age};
    my $g   = $_[0]->{gender};

   return 0 unless ($kg && $hr && $dur && $age && $g);

    my %c = (
        info => 'constants to be used for calculations m-males, f-females',
        m => {
            x1 => -55.0969,    # intercept effect on energy usage
            x2 => 0.6309,      # hr effect
            x3 => 0.1988,      # weight effect
            x4 => 0.2017,      # age effect
        },
        f => {
            x1 => -20.4022,
            x2 => 0.4472,
            x3 => 0.1263,
            x4 => 0.074,
        }
      );

    my $kcal =
        (
          ( $c{$g}{x1} +
           ($c{$g}{x2} * $hr) +
           ($c{$g}{x3} * $kg) +
           ($c{$g}{x4} * $age)
          ) / 4.184		# result in kcal, otherwise kJ
        ) * $dur;

    return $kcal;
}

sub max_hr {
  my $max_hr = 208 - (0.7 * $_[0]->{age});     # hax heart rate depending on age
  return $max_hr;
}

sub wl_hr{
  # burn fat
  my $hr = 0.65 * $_[0]->{max_hr};
  return $hr;
}

sub aerobic_hr{
  # Increase stamina & endurance
  my $hr = 0.75 * $_[0]->{max_hr};
  return $hr;
}

sub cond_hr{
  # Fitness conditioning, muscle building, and athletic training
  my $hr = 0.85 * $_[0]->{max_hr};
  return $hr;
}
