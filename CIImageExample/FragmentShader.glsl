#!/bin/sh

#  FragmentShader.sh
#  CIImageExample
#
#  Created by IYNMac on 25/4/17.
#  Copyright © 2017年 IYNMac. All rights reserved.


#Fragment shader – 在你的场景中，大概每个像素都会调用的程序，称为“片段着色器”。
#在一个简单的场景，也是刚刚说到的长方形。这个长方形所覆盖到的每一个像素，都会调用一次fragment shader。
#片段着色器的责任是计算灯光，以及更重要的是计算出每个像素的最终颜色


# step1: precision mediump float设置float的精度为mediump，还可设置为lowp和highp，主要是出于性能考虑。
# step2: gl_FragColor是fragment shader唯一的内建输出变量，设置像素的颜色。这里设置所有像素均为红色。


#precision mediump float;

#未声明为attribute的变量即为输出变量（如DestinationColor），将传递给fragment shader。
#varying表示依据两个顶点的颜色，平滑地计算出顶点之间每个像素的颜色。
varying lowp vect DestinationColor;


void main(void){

    #这里，fragment shader接收来自vertex shader的变量DestinationColor，赋值给gl_FragColor，再输出至OpenGLES。即每个像素的颜色由DestinationColor决定，这样可在代码中精确控制每个像素的颜色。
    gl_FragColor = DestinationColor;
    #gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
