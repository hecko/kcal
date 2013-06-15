#!/usr/bin/perl

# This calculator is based on the equations (shown below) derived by LR Keytel, JH Goedecke,
# TD Noakes, H Hiiloskorpi, R Laukkanen, L van der Merwe, and EV Lambert for their study
# titled "Prediction of energy expenditure from heart rate monitoring during submaximal exercise."
# http://www.shapesense.com/fitness-exercise/calculators/heart-rate-based-calorie-burn-calculator.aspx
#
# calculate HR for weight loss and cardio
# http://www.spinning.com/en/media/spinning_news_for_spinning_enthusiasts/january09_1.html

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

$json->{max_hr}    = max_hr($json);
$json->{cardio_hr} = cardio_hr($json);
$json->{wl_hr}     = wl_hr($json);

say "Max HR based on age (".$json->{age}."): ".int $json->{max_hr};
say "Ideal HR for cardio: ".int $json->{cardio_hr};
say "Ideal HR for weight loss: ".int $json->{wl_hr};

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

    my $kcal = kcal($data);
    my $bmi  = bmi($data);

    say $line->{date}.": ".(int $kcal)." kcal; ".(sprintf ("%.2f", $bmi))." bmi; ".
        "avg hr: ".$line->{hr_avg}."; ".$line->{note};

    push @www_data, { date => $line->{date},
                      kcal => $kcal,
                      kg   => $line->{weight},
                      bmi  => $bmi };
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
#$cal{calc}{burned_kj} = $cal{calc}{burned_kcal} * 4.184;
#$cal{calc}{burned_fat_g} = $cal{calc}{burned_kj} / 37;

sub wl_hr{
  my $hr = 0.70 * $_[0]->{max_hr};
  return $hr;
}

sub cardio_hr{
  my $hr = 0.80 * $_[0]->{max_hr};
  return $hr;
}

