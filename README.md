
![example](https://github.com/user-attachments/assets/fd59c64a-aceb-465e-a4d5-2814040f3378)


### vBorder is 微边

vBorder是一款为摄影作品添加EXIF个性边框的工具。

### 幫助信息
```
perl vborder.pl -h
    ./vBorder v1.0，为摄影作品添加EXIF个性边框
    -f	src/目录下带后缀的照片文件名
    -t	边框风格，预设'black、dark、light、white'四种，可按需增删改'%border_styles'
    -w	生成边框图宽度，默认为1080
    -p	仅列印照片基本信息，包括自动读取出的EXIF信息和程序参数指定信息，程序参数优先
      	*当EXIF信息不全不准时（如胶片作品）使用以下参数设置，参数值字符串存在空格时用单引号包含
    -c	相机制作商
    -m	相机型号
    -l	镜头类型
    -i	拍摄ISO
    -a	拍摄光圈
    -s	拍摄快门
        作者：GitHub@shanleiguang@, 小红书@兀雨书屋，2025
```
### 举个例子
```
perl vborder.pl -f L1002860.jpg -p
------------------------------------------------------------
Srouce Photo: src/L1002860.jpg
------------------------------------------------------------
Photo Information
------------------------------------------------------------
	Camera Maker: Leica Camera AG
	Camera Model: M Monochrom
	Lnes Model:
	ISO: 320
	Aperture: 3.4
	Shutter Speed: 1/60
------------------------------------------------------------
	Border Style: black
	Resize Width: 1080
------------------------------------------------------------
Boder Photo: dst/L1002860_black.jpg
------------------------------------------------------------
```
查看照片自带的EXIF关键信息。这张照片是我在广西拍摄的，用了Leica 50DR老镜头，因此相机不能读取镜头型号，镜头型号为空；另外，相机制作商字段有些长，显得啰嗦。
```
perl vborder.pl -f L1002860.jpg -c Leica -l 50DR
------------------------------------------------------------
Srouce Photo: src/L1002860.jpg
------------------------------------------------------------
Photo Information
------------------------------------------------------------
	Camera Maker: Leica
	Camera Model: M Monochrom
	Lnes Model: 50DR
	ISO: 320
	Aperture: 3.4
	Shutter Speed: 1/60
------------------------------------------------------------
	Border Style: black
	Resize Width: 1080
------------------------------------------------------------
Boder Photo: dst/L1002860_black.jpg
------------------------------------------------------------
```
用程序参数设置相机制作商、镜头型号信息。效果如下：
![L1002860_black](https://github.com/user-attachments/assets/bf388e6d-967e-4a93-a932-8a0611dfc833)

```
perl vborder.pl -f L1002860.jpg -c Leica -l 50DR -t light
------------------------------------------------------------
Srouce Photo: src/L1002860.jpg
------------------------------------------------------------
Photo Information
------------------------------------------------------------
	Camera Maker: Leica
	Camera Model: M Monochrom
	Lnes Model: 50DR
	ISO: 320
	Aperture: 3.4
	Shutter Speed: 1/60
------------------------------------------------------------
	Border Style: light
	Resize Width: 1080
------------------------------------------------------------
Boder Photo: dst/L1002860_light.jpg
------------------------------------------------------------
```
将照片边框风格设置为light风格。效果如下：
![L1002860_light](https://github.com/user-attachments/assets/42371f7b-d421-4361-9aed-e469c55d335f)

## 赞助支持 Sponsorship
![image](https://github.com/shanleiguang/vRain/blob/main/sponsor_new.png)  
