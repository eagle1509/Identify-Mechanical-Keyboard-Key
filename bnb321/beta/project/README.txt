Readme.txt
Created by Shengxiang Zhu(Troy) on 3/10/2016
Updated by Shengxiang Zhu(Troy) on 4/14/2016

This is the ECE 573 project of team bnb321.

The introduction video is in this foler named “Alpha-Release-Introduction.MOV”.

To open the Alpha release project, please double click the "project-bnb321.xcworkspace" file. Since we used an external library to process our audio signal, we integrated the library into our project. Please make sure that you double click the "xcworkspace" file. DO NOT OPEN THE XCODEPROJ FILE! If you open the xcodeproj file, it may not compile.

In the Alpha release we have built the fundamental structure of our project and implemented all the important interfaces, including the detection of audio, FFT process, library bridging header file, etc. In this release the app is able to detect real-time audio input and calculate FFT in real time and output the FFT result. In this Alpha version we will only show you the peak frequency in real time. The remaining features will be finished in the following days. 

In the Beta release we have added a new library to help plot the FFT graph. The main algorithm in this release is analyzing the peak frequency index buffer so that we can detect the switch click sound and classify the green and blue switch, with a success rate above 90% in a quiet environment. The detection of white switch is harder and the success rate is lower. We will use KNN machine learning algorithm to implement the remaining switches, which will be in the final release. The video introduction is on youtube.com and I have attached a shortcut for the video link, which is in the current folder.

The license we use is MIT license since the library we integrated is in MIT license. Please refer to the LICENSE file.

If you have any questions regaring the Alpha release, or if you have bug report, please email to szhu@email.arizona.edu.

