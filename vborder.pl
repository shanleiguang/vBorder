#!/usr/bin/perl
#为摄影作品添加EXIF风格化边框
#by shanleiguang@gmail.com, 2025
use strict;
use warnings;

use Image::Magick;
use Image::ExifTool;
use Getopt::Std;
use utf8;

$| = 1; #autoflush

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

my ($software, $version) = ('vBorder', 'v1.0');
my %opts;

getopts('hf:t:w:p:c:m:l:i:a:s:', \%opts);

print_help() and exit if($opts{'h'}); #帮助信息

print "error: no source photo para '-f'!\n" and exit if(not $opts{'f'}); #缺源照片'-f'参数
print "error: 'src/$opts{'f'} not found!\n" and exit if(not -f "src/$opts{'f'}"); #源照片不存在

my $srcfp = "src/$opts{'f'}";
my $resize_width = $opts{'w'} ? $opts{'w'} : 1080; #加边框前源照片的缩放宽度
my $border_style = $opts{'t'} ? $opts{'t'} : 'black'; #边框风格，默认为'black'
my %border_styles = (
    #边框颜色, 左边框宽, 右边框宽, 上边框宽, 下边框宽, LOGO文件路径, 字体文件路径, 边框文字大小、加粗、颜色
    'black' => ['#000000', 10, 10, 10, 60, 'Leica.png', 'NovaMono for Powerline.ttf', 20, 1, '#eeeeee'],
    'dark'  => ['#333333', 10, 10, 10, 60, 'Leica.png', 'NovaMono for Powerline.ttf', 20, 1, '#eeeeee'],
    'light' => ['#cccccc', 10, 10, 10, 60, 'Leica.png', 'NovaMono for Powerline.ttf', 20, 1, '#333333'],
    'white' => ['#ffffff', 10, 10, 10, 60, 'Leica.png', 'NovaMono for Powerline.ttf', 20, 1, '#333333'],
);

my ($bc, $lm, $rm, $tm, $bm, $lf, $ft, $fs, $fw, $fc) = @{$border_styles{$border_style}}; #边框风格参数

$lf = "logo/$lf";
$ft = "fonts/$ft";
print "error: logo iamge '$lf' not found!\n" and exit if(not -f $lf); #logo文件不存在
print "error: font file '$ft' not found!\n" and exit if(not -f $ft); #font字体文件不存在

my $dstfp = 'dst/'.(split /\./, $opts{'f'})[0]."_$border_style.jpg";
#读取源照片EXIF信息
my %exif = get_exif($srcfp);
#优先使用程序指定参数值，其次使用读取源照片的EXIF值，方便手工指定
my $camera_maker = $opts{'c'} ? $opts{'c'} : $exif{'EXIF'}{'Make'} ? $exif{'EXIF'}{'Make'} : '';
my $camera_model = $opts{'m'} ? $opts{'m'} : $exif{'EXIF'}{'Camera Model Name'} ? $exif{'EXIF'}{'Camera Model Name'} : '';
my $lens_model = $opts{'l'} ? $opts{'l'} : $exif{'EXIF'}{'Lens Model'} ? $exif{'EXIF'}{'Lens Model'} : '';
my $iso = $opts{'i'} ? $opts{'i'} : $exif{'EXIF'}{'ISO'} ? $exif{'EXIF'}{'ISO'} : '';
my $aperture = $opts{'a'} ? $opts{'a'} : $exif{'EXIF'}{'F Number'} ? $exif{'EXIF'}{'F Number'} : '';
my $shutter_speed = $opts{'s'} ? $opts{'s'} : $exif{'EXIF'}{'Shutter Speed Value'} ? $exif{'EXIF'}{'Shutter Speed Value'} : '';

print '-'x60, "\n";
print "Srouce Photo: $srcfp\n";
print '-'x60, "\n";
print "Photo Information\n";
print '-'x60, "\n";
print "\tCamera Maker: $camera_maker\n";
print "\tCamera Model: $camera_model\n";
print "\tLnes Model: $lens_model\n";
print "\tISO: $iso\n";
print "\tAperture: $aperture\n";
print "\tShutter Speed: $shutter_speed\n";
print '-'x60, "\n";
print "\tBorder Style: $border_style\n";
print "\tResize Width: $resize_width\n";
print '-'x60, "\n";

exit if(defined $opts{'p'}); #仅打印当前参数信息，按需设置参数为自己想要的文字

#边框文字组成：相机制造商 相机型号 镜头型号 （拍摄ISO，拍摄光圈，拍摄快门）
my $border_text;
$border_text.= $camera_maker ? $camera_maker : 'unkown';
$border_text.= $camera_model ? ' '.$camera_model : ' unkown';
$border_text.= $lens_model ? ' '.$lens_model : ' unkown';
$border_text.= ' (';
$border_text.= $iso ? 'ISO'.$iso : 'ISOunkown';
$border_text.= $aperture ? ', '.$aperture : ', unkown';
$border_text.= $shutter_speed ? ', '.$shutter_speed : ', unkonw';
$border_text.= ')';
$border_text =~ s/^\s+//;
$border_text =~ s/\s+$//;
$border_text =~ s/\s{2,}/ /g;

my $td = 50; #常用间距
my $pimg = Image::Magick->new();
my $limg = Image::Magick->new(); #logo图
my ($pw, $ph, $lw, $lh);

$limg->ReadImage($lf);
($lw, $lh) = $limg->Get('width', 'height');
$limg->AdaptiveResize(width => 100, height => int($lh*100/$lw), filter => 'Lanczos') if($lw > 100);  #缩小使用Lanczos过滤器
$limg->AdaptiveResize(width => 100, height => int($lh*100/$lw), filter => 'Hermite', blur => 0.9) if($lw < 100);  #放大使用Hermite过滤器
($lw, $lh) = $limg->Get('width', 'height'); #更新
$limg->AdaptiveSharpen(); #锐化

$pimg->ReadImage($srcfp);
$pimg->Set(type => 'TrueColor');
($pw, $ph) = $pimg->Get('width', 'height'); #读取宽、高
$pimg->AdaptiveResize(width => $resize_width, height => int($ph*$resize_width/$pw), filter => 'Lanczos') if($pw > 1080); #缩小使用Lanczos过滤器
$pimg->AdaptiveResize(width => $resize_width, height => int($ph*$resize_width/$pw), filter => 'Hermite', blur => 0.9) if($pw < 1080); #放大使用Hermite过滤器
($pw, $ph) = $pimg->Get('width', 'height'); #更新宽、高
$pimg->Extent(width => $pw+$lm+$rm, height => $ph+$tm+$bm, x => -$lm, y => -$tm, background => $bc); #扩展上、下、左、右边框
($pw, $ph) = $pimg->Get('width', 'height'); #更新宽、高
$pimg->Composite(image => $limg, compose => 'over', x => $td/2, y => $ph-$lh-$td/2); #合并logo图
$pimg->Clamp();
$pimg->Annotate(
     text        => $border_text,
     font        => $ft,
     pointsize   => $fs,
     x           => $lw+$td,
     y           => $ph-$td/2,
     fill        => $fc,
     stroke      => $fc,
     strokewidth => $fw,
);
$pimg->Write($dstfp);
print "Boder Photo: $dstfp\n";
print '-'x60, "\n";

sub print_help {
    print <<END
    ./$software $version，是一款为摄影作品添加EXIF个性边框的工具
    -f\tsrc/目录下带后缀的照片文件名
    -t\t边框风格，预设'black、dark、light、white'四种，可按需增删改'%border_styles'
    -w\t生成边框图宽度，默认为1080
    -p\t仅列印照片基本信息，包括自动读取出的EXIF信息和程序参数指定信息，程序参数优先
      \t*当EXIF信息不全不准时（如胶片作品）使用以下参数设置，参数值字符串存在空格时用单引号包含
    -c\t相机制造商
    -m\t相机型号
    -l\t镜头类型
    -i\t拍摄ISO
    -a\t拍摄光圈
    -s\t拍摄快门速度
        作者：GitHub\@shanleiguang@, 小红书\@兀雨书屋，2025
END
}

sub get_exif {
    my $imgfile = shift;
    my $exifTool = new Image::ExifTool;
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

#ImageMagick AdaptiveResize Filters
#filter=>{Point, Box, Triangle, Hermite, Hanning, Hamming, Blackman, Gaussian, Quadratic, Cubic, Catrom, Mitchell, Lanczos, Bessel, Sinc}, 
#1. Interpolation Filters, such as 'Hermite', are ideal when greatly enlarging images, producing a minimum of blur in the final result, though the output could often be artificially sharpened more in post-processing.
#2. Gaussian-like Blurring Filters, such as 'Mitchell', work best for images which basically consist of line drawings and cartoon like images. You can control the blurring versus the aliasing effects of the filter on the image using the special Filter Blur Setting.
#3. Windowed Sinc/Jinc Filters, and the Lagrange equivalent are the best filters to use with real-world images, and especially when shrinking images. All of them are very similar in basic results.
#   A larger support, or better still, lobe count setting, will generally produce an even better result, though you may get more ringing effects as well, but at a higher calculation cost.
#4. The Cubic Filters are a mixed bag of fast and simple filters, of fixed support (usually 2.0) which produces everything from the 'Hermite' smooth interpolation filter, the qualitatively assessed 'Mitchell' for image enlargements, 
#   the very blurry Gaussian-like 'Spline' filter, or a sharp, windowed-sinc type of filter using 'Catrom'.