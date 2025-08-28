#!/usr/bin/perl
#by shanleiguang@gmail.com, 2022.5
use strict;
use warnings;

use PDL;
use PDL::IO::Image;
use Image::Magick;
use Image::ExifTool;;
use perlchartdir;
use Getopt::Std;

$| = 1;

my %opts;

getopts('f:', \%opts);

my $fn = $opts{f};
my $exifTool = new Image::ExifTool;
my $logo = Image::Magick->new;
my $img_logo = 'logo.png';
my ($sdir, $ddir) = ('src', 'dst');

$logo->ReadImage($img_logo);
$logo->AdaptiveSharpen();

gen_histogram($sdir, $fn);
gen_invert($sdir, $fn);
gen_countourgram($sdir, $fn);
gen_border($sdir, $fn);

sub gen_invert {
    my ($cdir, $fn) = @_;
    my $img_fp = $cdir.'/'.$fn;
    my $img_invert_fp = 'dst/'.(split /\./, $fn)[0].'_invert.jpg';
    return if(-f $img_invert_fp);
    my $pim = Image::Magick->new();

    $pim->ReadImage($img_fp);
    $pim->Negate(gray => 'True');
    $pimg->Write($img_invert_fp);
    print "$img_fp -> $img_invert_fp\n";
}

sub gen_countourgram {
    my ($cdir, $fn) = @_;
    my $img_fp = $cdir.'/'.$fn;
    my $img_countour_fp = 'dst/'.(split /\./, $fn)[0].'_countourgram.jpg';
    return if(-f $img_countour_fp);
    my $pim = PDL::IO::Image->new_from_file($img_fp);
    my $width = $pim->get_width;
    my $height = $pim->get_height;
    if($width > 600) {
        $pim->rescale(600, 0);
        $width = $pim->get_width;
        $height = $pim->get_height;
    }
    $pim->flip_vertical();
    my $pdl = $pim->pixels_to_pdl();
    my @data = $pdl->list();
    my (@dataX, @dataY, @dataZ, $c, $layer, $cAxis, $colorGradient);
    
    foreach my $i (0..$width-1) { push @dataX, $i; };
    foreach my $i (0..$height-1) { push @dataY, $i; };
    for(my $xIndex = 0; $xIndex <= $width; ++$xIndex) {
        for(my $yIndex = 0; $yIndex <= $height; ++$yIndex) {
            my $zIndex = $height * $xIndex + $yIndex;
            $dataZ[$zIndex] = 255 - $data[$zIndex];
        }
    }

    $c = new XYChart($width + 90, $height + 90);
    $c->setPlotArea(40, 40, $width, $height, -1, -1, -1, 0xdd000000, -1);
    $c->xAxis()->setLinearScale(0, $width, 50);
    $c->yAxis()->setLinearScale(0, $height, 50);
    $layer = $c->addContourLayer(\@dataX, \@dataY, \@dataZ);
    $c->getPlotArea()->moveGridBefore($layer);
    $cAxis = $layer->setColorAxis($width + 40, 40, $perlchartdir::TopLeft, $height, $perlchartdir::Right);
    $colorGradient = [0xffffff, 0x000000];
    $cAxis->setColorGradient(0, $colorGradient);
    $c->makeChart($img_countour_fp);
    
    my $im_contour = PDL::IO::Image->new_from_file($img_countour_fp);
    my $impdl = $im_contour->pixels_to_pdl();
    my $new_width = $im_contour->get_width - 1;
    my $new_height = $im_contour->get_height - 11;
    my $impdl_cracked = $impdl->slice("0:$new_width", "0:$new_height")->copy();
    my $im_cracked = PDL::IO::Image->new_from_pdl($impdl_cracked);
    $im_cracked->save($img_countour_fp);
    print "$img_fp -> $img_countour_fp\n";
}

sub gen_histogram {
    my ($cdir, $fn) = @_;
    my $img_fp = $cdir.'/'.$fn;
    my $img_hist_fp = 'dst/'.(split /\./, $fn)[0].'_histogram.jpg';
    return if(-f $img_hist_fp);
    my $pim = PDL::IO::Image->new_from_file($img_fp);
    my $pdl = $pim->pixels_to_pdl();
    my ($xvals, $hist) = hist($pdl, 0, 255, 1);
    my @labels = $xvals->list();
    my @data = $hist->list();
    my ($c, $layer);
    
    $c = new XYChart(420, 150, 0x999999, 0x999999);
    $c->setPlotArea(50, 15, 340, 100, 0xbbbbbb, -1, -1, $c->dashLineColor(0x000000, 0x000103), $c->dashLineColor(0x000000, 0x000103));
    $c->xAxis()->setLabels(\@labels);
    $c->xAxis()->setLabelStep(25);
    $c->xAxis()->addZone(50, 75, 0xaaaaaa);
    $c->xAxis()->addZone(100, 125, 0xaaaaaa);
    $c->xAxis()->addZone(175, 200, 0xaaaaaa);
    $layer = $c->addAreaLayer();
    $layer->addDataSet(\@data)->setDataColor(0x666666);
    $layer->setLineWidth(1);
    $c->makeChart($img_hist_fp);

    my $him = PDL::IO::Image->new_from_file($img_hist_fp);
    my $hpdl = $him->pixels_to_pdl();
    my $new_width = $him->get_width - 1;
    my $new_height = $him->get_height - 11;
    my $hpdl_cracked = $hpdl->slice("0:$new_width", "0:$new_height")->copy();
    my $him_cracked = PDL::IO::Image->new_from_pdl($hpdl_cracked);
    
    $him_cracked->save($img_hist_fp);
    print "$img_fp -> $img_hist_fp\n";
}

sub gen_border {
    my ($cdir, $fn) = @_;
    my $img_fp = $cdir.'/'.$fn;
    my $img_bord_fp = 'dst/'.(split /\./, $fn)[0].'_border.jpg';;
    return if(-f $img_bord_fp);

    my %exif = get_exif($img_fp);
    my $camera_model = $exif{'EXIF'}{'Camera Model Name'} ? $exif{'EXIF'}{'Camera Model Name'} : '-';
    my $lens_model = $exif{'EXIF'}{'Lens Model'} ? $exif{'EXIF'}{'Lens Model'} : '-';
    my $iso = $exif{'EXIF'}{'ISO'} ? $exif{'EXIF'}{'ISO'} : '-';
    my $aperture = $exif{'EXIF'}{'F Number'} ? $exif{'EXIF'}{'F Number'} : '-';
    my $shutter_speed = $exif{'EXIF'}{'Shutter Speed Value'} ? $exif{'EXIF'}{'Shutter Speed Value'} : '-';
    my $magic = Image::Magick->new();
    my ($width, $height);

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
    $magic->Border(geometry =>'10x80',color => 'black');
    $magic->Crop(width => $width+20, height => $height+100, x => 0, y => 60); #20+80 
    $magic->Composite(image => $logo, compose => 'over', x => 40, y => $height+10);
    $magic->Clamp();
    $magic->Annotate(
         font      =>'DIN Condensed Bold.ttf',
         pointsize => 18,
         fill      => 'white', #last 2 digits transparency in hex ff=max
         text      => "$camera_model, $lens_model ( $aperture, $shutter_speed, $iso )",
         align     => 'left',
         x         => 120,
         y         => $height + 120,
    );
    $magic->write($img_bord_fp);
    print "$img_fp -> $img_bord_fp\n";
    undef $magic;
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