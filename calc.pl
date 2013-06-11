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
use Data::Dumper::Concise;
use File::Slurp;
use JSON::XS;

my $json = decode_json read_file('data/m.json');;

foreach my $line (@{$json->{data}}) {
    my $data = {
            weight => $json->{weight},
            hr => $line->{hr_avg},
            duration => $line->{duration},
            age => $json->{age},
            gender => $json->{gender},
        };
    say $line->{date}.": ".kcal($data)." kcal; ".$line->{note};
};

sub kcal {
    my $kg = $_[0]->{weight};
    my $hr = $_[0]->{hr};
    my $dur = $_[0]->{duration};
    my $age = $_[0]->{age};
    my $g = $_[0]->{gender};

    my %c = (
        info => 'constants to be used for calculations m-males, f-females',
        m => {
            x1 => -55.0969,
            x2 => 0.6309,
            x3 => 0.1988,
            x4 => 0.2017,
            x5 => 4.184
        },
        f => {
            x1 => -20.4022,
            x2 => 0.4472,
            x3 => 0.1263,
            x4 => 0.074,
            x5 => 4.184
        }
      );

    my $kcal =
        (
          ( $c{$g}{x1} +
           ($c{$g}{x2} * $hr) +
           ($c{$g}{x3} * $kg) +
           ($c{$g}{x4} * $age)
          ) / $c{$g}{x5}
        ) * $dur;

    return int $kcal;
}

#$cal{calc}{max_hr} = 208 - (0.7 * $i{age});     # hax heart rate depending on age
#$cal{calc}{burned_kj} = $cal{calc}{burned_kcal} * 4.184;
#$cal{calc}{burned_fat_g} = $cal{calc}{burned_kj} / 37;

#$cal{hr}{weight_loss}{info} = "heart rate for the most efficient far burning";
#$cal{hr}{weight_loss}{min} = 0.65 * $cal{calc}{max_hr};
#$cal{hr}{weight_loss}{avg} = 0.70 * $cal{calc}{max_hr};
#$cal{hr}{weight_loss}{max} = 0.75 * $cal{calc}{max_hr};

#$cal{hr}{cardio}{info} = "heart rate for the best cardio-vascular excercise";
#$cal{hr}{cardio}{min} = 0.75 * $cal{calc}{max_hr};
#$cal{hr}{cardio}{avg} = 0.80 * $cal{calc}{max_hr};
#$cal{hr}{cardio}{max} = 0.85 * $cal{calc}{max_hr};


##print Dumper \%cal;
