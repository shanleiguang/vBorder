#!/usr/bin/perl
#检查并更新照片的exif信息
#by shanleiguang@gmail.com, 2024
use strict;
use warnings;

use Image::Magick;
use Image::ExifTool;
use Getopt::Std;
use Data::Dumper;
use Encode;
use utf8;

$| = 1; #autoflush
binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

my ($software, $version) = ('exifupdate', 'v1.0');

my %opts;

#参数说明：
#f：src文件夹下原始照片文件名（含后缀）
#p：仅打印并退出
#u：设置更新，c：相机制作商，m：相机型号，l：镜头型号，i：拍摄ISO，a：拍摄光圈，s：拍摄快门，并保存为new打头的新照片文件
getopts('hpuf:c:m:l:i:a:s:', \%opts);

print_help() and exit if(defined $opts{'h'});

my $photo_srcfn = 'src/'.$opts{'f'};
my $photo_dstfn = 'src/new_'.$photo_srcfn;
my $exifTool = new Image::ExifTool;

$exifTool->Options(Unknown => 1);

my %exif = get_exif($photo_srcfn);
    
#image info
#my $img_orientation = $exif{'EXIF'}{'Orientation'} ? $exif{'EXIF'}{'Orientation'} : 'null';
my $img_width = $exif{'File'}{'Image Width'} ? $exif{'File'}{'Image Width'} : 'null';
my $img_height = $exif{'File'}{'Image Height'} ? $exif{'File'}{'Image Height'} : 'null';
#my $img_has_crop = $exif{'XMP'}{'Has Crop'} ? $exif{'XMP'}{'Has Crop'} : 'null';
    
#camera/lens info
my $camera_make = $exif{'EXIF'}{'Make'} ? $exif{'EXIF'}{'Make'} : 'null';
my $camera_model = $exif{'EXIF'}{'Camera Model Name'} ? $exif{'EXIF'}{'Camera Model Name'} : 'null';
my $lens_make = $exif{'EXIF'}{'Lens Make'} ? $exif{'EXIF'}{'Lens Make'} : 'null';
#my $lens_info = $exif{'EXIF'}{'Lens Info'} ? $exif{'EXIF'}{'Lens Info'} : 'null';
my $lens_model = $exif{'EXIF'}{'Lens Model'} ? $exif{'EXIF'}{'Lens Model'} : 'null';
#my $lens_max_ape = $exif{'EXIF'}{'Max Aperture Value'} ? $exif{'EXIF'}{'Max Aperture Value'} : 'null';

#exposure info
#my $focal_length = $exif{'EXIF'}{'Focal Length'} ? $exif{'EXIF'}{'Focal Length'} : 'null';
my $iso = $exif{'EXIF'}{'ISO'} ? $exif{'EXIF'}{'ISO'} : 'null';
my $aperture = $exif{'EXIF'}{'F Number'} ? $exif{'EXIF'}{'F Number'} : 'null';
my $shutter_speed = $exif{'EXIF'}{'Shutter Speed Value'} ? $exif{'EXIF'}{'Shutter Speed Value'} : 'null';

foreach ($img_width, $img_height, $camera_make, $camera_model, $lens_make, $iso, $aperture, $shutter_speed) {
    s/^\s+//;
    s/\s+$//;
    s/\"//g;
}

if(defined $opts{'p'}) {
    print "$photo_srcfn ($img_width x $img_height) -> $camera_make | $camera_model | $lens_model | $iso $aperture $shutter_speed\n";
    exit;
}

if(defined $opts{'u'}) {
    if(defined $opts{'c'}) {
        $camera_make = $opts{'c'};
        $exifTool->SetNewValue('Make' => $camera_make);
    }
    if(defined $opts{'m'}) {
        $camera_model = $opts{'m'};
        $exifTool->SetNewValue('Camera Model Name' => $camera_model);
    }
    if(defined $opts{'l'}) {
        $lens_model = $opts{'l'};
        $exifTool->SetNewValue('Lens Model' => $lens_model);
    }
    if(defined $opts{'i'}) {
         $iso = $opts{'i'};
         $exifTool->SetNewValue('ISO' => $iso);
    }
    if(defined $opts{'a'}) {
        $aperture = $opts{'a'};
        $exifTool->SetNewValue('F Number' => $aperture);
    }
    if(defined $opts{'s'}) {
        $shutter_speed = $opts{'s'};
        $exifTool->SetNewValue('Shutter Speed Value' => $shutter_speed)
    }
    print Dumper($exifTool);
    $exifTool->WriteInfo($photo_srcfn);
}

sub print_help {
    print <<END
   ./$0 更新照片EXIF信息并保存为新图片
    -h\t帮助信息
    -f\tsrc目录下的原始照片文件名（含后缀）
    -p\t仅打印原图EXIF信息，判断是否需要更新某字段
    -u\t更新模式
    -c\t相机制作商
    -m\t相机型号
    -l\t镜头型号
    -i\t拍摄ISO
    -a\t拍摄光圈
    -s\t拍摄快门
        作者：GitHub\@shanleiguang@, 小红书\@兀雨书屋，2025
END
}

sub get_exif {
    my $imgfile = shift;
    my %exif;
    my $info = $exifTool->ImageInfo($imgfile);
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