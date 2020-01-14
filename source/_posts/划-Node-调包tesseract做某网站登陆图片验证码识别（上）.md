---
title: '[划][Node]调包tesseract做某网站登陆图片验证码识别（上）'
date: 2019-09-29 12:30:28
updated: 2019-09-29 12:30:28
tags:
---
因业务需要，要做某网站的模拟登陆，有个比较简单的图片验证码。

之前登陆的话，同事用的基本都是js逆向。然而已经是前同事了，然而逆向的工作量我是不愿意接受的，所以划水的时候做了一个小demo，尝试解决这个问题。

当然了网站名字不好透露，这里放一部分测试数据。

![image](https://upload-images.jianshu.io/upload_images/14253223-3d9d278612337bb0.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![image](https://upload-images.jianshu.io/upload_images/14253223-d1e10ad9d6005ad9.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![image](https://upload-images.jianshu.io/upload_images/14253223-1fd6eaf04fdbf74b.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![image](https://upload-images.jianshu.io/upload_images/14253223-c559f65081dfd66d.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![image](https://upload-images.jianshu.io/upload_images/14253223-c67c2024eb919588.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![image](https://upload-images.jianshu.io/upload_images/14253223-8e01dc99ca1a6620.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

思路：

首先看下商业上是怎么处理图片验证码的，借鉴一下。

百度图像识别，图像文本识别等关键词，出现了ali和tx的广告（打钱），有一个关键词频繁出现：OCR；于是又搜了一下OCR，OCR （Optical Character Recognition，光学字符识别），这个应该算是比较具体的技术名字了；拿这个关键词去GitHub搜一下，果然有[现成的东西](https://github.com/tesseract-ocr/tesseract)

下载下来好好康康，C++写的，win/linux都能用，直接用cli操作，指定输出路径。那这就很勇了，安装走起。

自己用画图手写了几个算式，识别效果还不错。然而直接用目标网站的图片就凉凉了……

这里简单分析了一下，应该是图片内容有问题，可以看上面的测试数据集，多了一部分干扰线；再一个tesseract的设置应该也有问题，虽然什么都没有识别出来，但是结果集是一个四行的空文档。后者直接看tesseract的文档，有一个配置项--psm，是预指定的识别模式，看了一下选择13，单行识别模式。前者的话，这一版是暂时做了简单的图像处理。

那么整体的处理模块就分为两个部分了：第一个，图像去干扰；第二个，调包生成结构再处理；

一、图像去干扰

这个图片集本身是比较简单的（这也是我做着玩也能做出来的原因，笑，不过思路还是可以分享一下）

分析一下图片，第一，图片四周一圈单像素的干扰信息，看上去就是一个黑框；第二，图片中的干扰像素和信息像素颜色区分度还算是比较高的，信息像素基本是偏向黑色的，后期查看虽然不是完全的#000000，rgb值都确实是普遍小于干扰像素的。那么就设置一个阈值，筛选出不是那么黑的像素点，直接涂白就行了。

具体代码如下：

```javascript
const getPixels = require('get-pixels') // 这个包比较老，只能用回调，promisify都救不回来

const fs = require('fs')

const jpeg = require('jpeg-js') // 只有getPixels，没有setPixels。手动反向操作加密图片内容后再输出

const { exec } = require('child_process')

const detach = 30 // 颜色阈值，一边试一边调，手动调到一个合适的水平

let pic = 'math'

process.argv[2] && (pic += process.argv[2])

const solve = () => {

  getPixels(`${pic}.jpeg`, (err, pixels) => {

    if (err) {

      return

    }

    let x = pixels.shape[0]

    let y = pixels.shape[1]

    for (let i = 0 ; i < x ; i++) {

      for (let j = 0 ; j < y ; j++) {

        let r = pixels.get(i, j, 0)

        let g = pixels.get(i, j, 1)

        let b = pixels.get(i, j, 2)

        // let a = pixels.get(i, j, 3)

        if (r > detach || g > detach || b > detach || i === 0 || j === 0 || i === (x - 1) || j === (y - 1)) {

          pixels.set(i, j, 0, 255)

          pixels.set(i, j, 1, 255)

          pixels.set(i, j, 2, 255)

        }

      }

    }

    let temp = {

      width: x,

      height: y,

      data: pixels.data

    }

    fs.writeFileSync('./out.jpeg', jpeg.encode(temp).data)

   // orc() // 调包处理

  })

}

```

去干扰前后对比

![image](https://upload-images.jianshu.io/upload_images/14253223-567c2badc0273dcd.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![image](https://upload-images.jianshu.io/upload_images/14253223-51ab3b3b109a42fd.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

二、调包处理

这个没啥好说的，windows下的安装包[下载地址](https://digi.bib.uni-mannheim.de/tesseract/tesseract-ocr-w64-setup-v5.0.0-alpha.20190708.exe)

这个一路点点点下一步就好，安装完需要手动设置环境变量，环境变量不会设置的百度一下吧……

会linux的就不用说了吧……

对应代码如下：

```javascript
const orc = () => {

  exec('tesseract out.jpeg out --psm 13', () => {

    const s = fs.readFileSync('./out.txt').toString('utf8')

    let res

    let nums = s.match(/\d+/g)

    if (s.match(/\+/)) {

      res = Number(nums[0]) + Number(nums[1])

    } else if (s.match(/-/)) {

      res = Number(nums[0]) - Number(nums[1])

    } else if (s.match(/x/)) {

      res = Number(nums[0]) * Number(nums[1])

    } else if (s.match(/÷/)) {

      res = Number(nums[0]) / Number(nums[1])

    }

    console.log(res)

  })

}

```

差不多就是这样了，试一试，发现了两个问题，乘号被识别为了小写字母字符x，这个将就一下也可以用；除号基本识别不出来，这个就不是三分钟能解决的问题了。好在这个东西识别错了也没什么大问题，再调一次接口就好了。

所以既然这一期的标题里有一个“上”字，那这篇文章就讲到这里了；下一期划水的时候，我会讲一下tesseract训练集，专门处理一下乘号、除号无法识别的问题。
