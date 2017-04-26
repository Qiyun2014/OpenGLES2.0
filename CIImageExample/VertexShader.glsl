#!/bin/sh

#  VertexShader.sh
#  CIImageExample
#
#  Created by IYNMac on 25/4/17.
#  Copyright © 2017年 IYNMac. All rights reserved.

#Vertex shader – 在你的场景中，每个顶点都需要调用的程序，称为“顶点着色器”。
#假如你在渲染一个简单的场景：一个长方形，每个角只有一个顶点。于是vertex shader 会被调用四次。
#它负责执行：诸如灯光、几何变换等等的计算。得出最终的顶点位置后，为下面的片段着色器提供必须的数据。


# step1: attribute声明vertex shader接收的变量，针对每一个顶点的数据。属性可理解为针对每一个顶点的输入数据，只有在vertex shader中才有，在fragment shader中没有。vec4表示由4部分组成的矢量。这里的Position用来传入顶点vertex的位置数据。
# step2: main是shader脚本的入口。
# step3: gl_Position是vertex shader内建的输出变量，传递给fragment shader，必须设置。这里将Position直接传递给fragment shader。


# <Vertex shader与Fragment shader的差异>
#shader脚本中有三种级别的精度：lowp，mediump，highp。如precision highp float; 。在vertex shader中，int和float都默认为highp级别。而fragment shader中没有默认精度，必须设置精度描述符，一般设为mediump即可。
#attribute只作用于vertex shader中，表示接收的变量。在vertex shader中，若没有attribute则为输出变量（输出至fragment shader）。
#vertex shader的默认输出变量至少应该有gl_Position，另外有两个可选的gl_FrontFacing和gl_PointSize。而fragment shader只有唯一的varying输出变量gl_FragColor。
#Uniform是全局变量，可用于vertex shader和fragment shader。在vertex shader中通常是变换矩阵、光照参数、颜色等，。在fragment shader中通常是雾化参数、纹理参数等。OpenGLES 2.0规定所有实现应该支持的最大vertex shader的uniform变量个数不能少于128个，而最大fragment shader的uniform变量个数不能少于16个。
#simpler是一种特殊的uniform，用于呈现纹理，可用于vertex shader和fragment shader。

attribute vec4 Position;    #position of vertex
attribute vec4 SourceColor; #color of vertex

varying vec4 DestinationColor; #will pass out to fragment shader

void main(Void){

    DestinationColor = SourceColor;
    gl_Position = Position;
}
