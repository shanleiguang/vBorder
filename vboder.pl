#!/usr/bin/perl
#by shanleiguang@gmail.com, 2022.5
use strict;
use warnings;
use Image::Magick;
use Image::ExifTool;;

$| = 1;

my ($sdir, $bdir, $ldir, $fdir) = ('tmp', 'borders', 'logos', 'fonts');
my $exifTool = new Image::ExifTool;
my %border_styles = (
    #border-color, left, right, top, bottom, logo, font, font-color
    'black' => ['black', 10, 10, 20, 80, 'Leica.png', 'DIN Condensed Bold.ttf', 18, 'white'],
    'white' => ['white', 10, 10, 20, 80, 'Leica.png', 'DIN Condensed Bold.ttf', 18, 'black'],
    'dark'  => ['#282828', 10, 10, 20, 80, 'Leica.png', 'NovaMono for Powerline.ttf', 18, 'white'],
);

opendir SDIR, $sdir;
foreach my $fn (readdir SDIR) {
    next if($fn =~ m{^\.+$});
    next if($fn !~ m{jpg$}i);
    gen_border($fn, 'dark');
}
closedir(SDIR);

sub gen_border {
    my ($fn, $sn) = @_;
    my $img_fp = "$sdir/$fn";
    my $img_bord_fp = "$bdir/$fn";
    return if(-f $img_bord_fp);
    
    my %exif = get_exif($img_fp);
    my $camera_model = $exif{'EXIF'}{'Camera Model Name'} ? $exif{'EXIF'}{'Camera Model Name'} : '-';
    my $lens_model = $exif{'EXIF'}{'Lens Model'} ? $exif{'EXIF'}{'Lens Model'} : '-';
    my $iso = $exif{'EXIF'}{'ISO'} ? $exif{'EXIF'}{'ISO'} : '-';
    my $aperture = $exif{'EXIF'}{'F Number'} ? $exif{'EXIF'}{'F Number'} : '-';
    my $shutter_speed = $exif{'EXIF'}{'Shutter Speed Value'} ? $exif{'EXIF'}{'Shutter Speed Value'} : '-';

    my ($bc, $lm, $rm, $tm, $bm, $lf, $ft, $fs, $fc) = @{$border_styles{$sn}};
    my ($logo_fp, $font_fp) = ("$ldir/$lf", "$fdir/$ft");
    my $magic = Image::Magick->new();
    my $logo = Image::Magick->new();
    my ($width, $height);

    $logo->ReadImage($logo_fp);
    $logo->AdaptiveSharpen();
    $magic->ReadImage($img_fp);
    ($width, $height) = $magic->Get('width', 'height');
    #AdaptiveResize
    #geometry=>geometry, width=>integer, height=>integer, 
    #filter=>{Point, Box, Triangle, Hermite, Hanning, Hamming, Blackman, Gaussian, Quadratic, Cubic, Catrom, Mitchell, Lanczos, Bessel, Sinc}, 
    #support=>double, blur=>double
    #1. Interpolation Filters, such as 'Hermite', are ideal when greatly enlarging images, producing a minimum of blur in the final result, though the output could often be artificially sharpened more in post-processing.
    #2. Gaussian-like Blurring Filters, such as 'Mitchell', work best for images which basically consist of line drawings and cartoon like images. You can control the blurring versus the aliasing effects of the filter on the image using the special Filter Blur Setting.
    #3. Windowed Sinc/Jinc Filters, and the Lagrange equivalent are the best filters to use with real-world images, and especially when shrinking images. All of them are very similar in basic results.
    #   A larger support, or better still, lobe count setting, will generally produce an even better result, though you may get more ringing effects as well, but at a higher calculation cost.
    #4. The Cubic Filters are a mixed bag of fast and simple filters, of fixed support (usually 2.0) which produces everything from the 'Hermite' smooth interpolation filter, the qualitatively assessed 'Mitchell' for image enlargements, 
    #   the very blurry Gaussian-like 'Spline' filter, or a sharp, windowed-sinc type of filter using 'Catrom'.
    if($width > 1080) {
        $height = int($height*1080/$width);
        $width = 1080;
        $magic->AdaptiveResize(width => $width, height => $height, filter => 'Lanczos');
    }
    if($width < 1080) {
        $height = int($height*1080/$width);
        $width = 1080;
        $magic->AdaptiveResize(width => $width, height => $height, filter => 'Hermite');
    }
    $magic->Border(geometry => $lm.'x'.$bm, color => $bc);
    $magic->Crop(width => $width+$lm*2, height => $height+$tm+$bm, x => 0, y => $bm-$tm); #20+80 
    $magic->Composite(image => $logo, compose => 'over', x => 40, y => $height+10);
    $magic->Clamp();
    $magic->Annotate(
         font      => $font_fp,
         pointsize => $fs,
         fill      => $fc,
         text      => "$camera_model, $lens_model ( $aperture, $shutter_speed, $iso )",
         align     => 'left',
         x         => 120,
         y         => $height + 120,
    );
    $magic->write($img_bord_fp);
    print "$img_fp -> $img_bord_fp\n";
    undef $magic, $logo;
}

sub get_exif {
    my $imgfile = shift;
    my $info = $exifTool->ImageInfo($imgfile);
    my %exif;
    foreach my $tag ($exifTool->GetFoundTags('Group0')) {
        my $group = $exifTool->GetGroup($tag);
        my $desc = $exifTool->GetDescription($tag);
        my $val = $info->{$tag};
        if (ref $val eq 'SCALAR') {
            if ($$val =~ /^Binary data/) {
                $val = "($$val)";
            } else {
                my $len = length($$val);
                $val = "(Binary data $len bytes)";
            }
        }
        $exif{$group}{$desc} = $val;
    }
    return %exif;
}