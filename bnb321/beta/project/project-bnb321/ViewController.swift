//
//  ViewController.swift
//  project-bnb321
//
//  Created by Troy on 3/1/16.
//  Copyright © 2016 Troy. All rights reserved.
//

//--------------------------------------------------------------------------------------------------------

// requirements

// ECE 473/573 Project
// Requirements
// Ce Wang, Shengxiang Zhu
// 3/31/2016
//
// (B requirements)
// 1.1 This application is able to classify different mechanical keyboards by analyzing the sound come from the keyboard, assuming that it works in a quiet environment.
// 1.2 This application would display the result of classification given a certain sound input.
// 1.3 This application would be able to classify at least 2 kinds of typical mechanical keyboard switch.
//
// (A requirements)
// 2.1 This application could work in a normal environment where there might be some noise.
// 2.2 This application would be able to display the FFT graph of the input signal.
// 2.3 This application would be able to classify at least 3 kinds of switches.

//--------------------------------------------------------------------------------------------------------


//  Notes:

//  The above is the requirements of this project. I posted it here for our convenience.  --Troy 3/2/2016

//  We will develop this app on iOS 9.2. Make sure the iPhone is upgraded into iOS 9.2. --Troy 3/2/2016

//  I'm considering which API to use, the AudioKit.io or the EZAudio. I will test them and decide. --Troy 3/2/2016

//  I installed the EZAudio Framework via CocoaPod to this project in order to implement the FFT quickly and easily. PLease make sure that when open the project, always open the xcworkspace file, not the xcodeproj file! --Troy 3/2/2016

//  For the FFT, we can refer to the sample code of EZAudioSample which is in the EZAudio-Swift-master folder. --Troy 3/2/2016

//  I have constructed the structure of our project, which is now able to receive audio in real time and do FFT and the real-time magnitude-frequency relationship. --Troy 3/9/2016

//  I am using the peak frequency indices to classify the different switches, which is able to classify 2 switches. In order to make full use of the FFT data, I will improve this kind of classification method and use KNN algorithm instead to try to detect and classify more switches, which I believe is possible. --Troy 4/14/2016

//  I have built the test codes to test classification algorithm. --Troy 4/14/2016

//  In the final release, I will cancel the buffer which was used to record the collection of peak frequency indices and only record the first detected fft data and ultilize the KNN algorithm to classify the switches. Since it is a machine learning algorithm, I might integrate some learning process in the UI interface or in the background. --Troy 4/14/2016

//--------------------------------------------------------------------------------------------------------


import UIKit
import Charts

// This is the windows size which is used to calculate FFT.
let FFTViewControllerFFTWindowSize : vDSP_Length = 4096
let windowSize = Int(FFTViewControllerFFTWindowSize)

// Set high pass value in order to filter the low frequency noise. 200 (index) -> 2153Hz.
let highpass: vDSP_Length = 700

//var blue=0
//var v=3

// We integrated EZAudio library into our project.
class ViewController: UIViewController, EZMicrophoneDelegate, EZAudioFFTDelegate {

    //Define a timer
    var timer = NSTimer()
    
    //Define a timer flag
    var timerSet = 0
    
    //Define a buffer to store the fft data of a single stroke of key
    var buffer: [UInt] = []
    
    //Define a fft data buffer to store the fft data into a 2D array for calculation of average
    var fftbuffer: [[Double]] = []
    
    //Define a fft data buffer to store the 1200th data
    var buffer1200: [Double] = []
    
    //Define a temp array to temporarily store fft data
    var tempArray: [Double] = []
    
    //Define a calculated fftdata for plot
    var avgfftdata: [Double] = []
    
    //Define the result
    var result = ""
    
    //fftPlot to plot the fft chart
    @IBOutlet weak var fftPlot: BarChartView!
    
    //Define a set which stores the blue key characteristic frequency indices
    var bluemfi: Set<UInt> = []
    
    //Define a set which stores the green key characteristic frequency indices
    var greenmfi: Set<UInt> = []
    
    //Define a set which stores the white key characteristic frequency indices
    var whitemfi: Set<UInt> = []
    
    //This label is show the peak frequency.
    @IBOutlet weak var resultLabel: UILabel!
    
    //Set microphone
    var microphone: EZMicrophone!;
    
    //Set fft calculator
    var fft : EZAudioFFTRolling = EZAudioFFTRolling()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setmfi()
        
        fftPlot.noDataText = "No FFT Data"
        
        //Open the microphone
        let session = AVAudioSession.sharedInstance()
   
        do {
            
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            
        } catch {
        
            // error
            
        }
        
        do {
            
            try session.setActive(true)
            
        } catch {
            
            // error
            
        }

        // Set microphone and start to detect sound
        self.microphone = EZMicrophone(microphoneDelegate: self, startsImmediately: true)
        
        // Set fft calculator as rolling mode which is able to calculate accurate FFT result.
        self.fft = EZAudioFFTRolling(windowSize: FFTViewControllerFFTWindowSize, sampleRate:Float(self.microphone.audioStreamBasicDescription().mSampleRate), delegate: self)
        
        // Change the label to show frequency
        resultLabel.text = "frequency and result"
        
    }
    
    // This is to tell the fft calculate FFT result once received audio.
    func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        
        self.fft.computeFFTWithBuffer(buffer[0], withBufferSize: bufferSize)
        
    }

    // This is to show the FFT result once FFT is calculated.
    func fft(fft: EZAudioFFT!, updatedWithFFTData fftData: UnsafeMutablePointer<Float>, bufferSize: vDSP_Length) {
        
        // This is to get the max frequency.
        //let maxFrequency = fft.maxFrequency
        //let frequency1 = fft.fftData[96]
        //let maxFrequencyIndex = fft.maxFrequencyIndex
        var mfi = fft.maxFrequencyIndex
        //let noisei: Set<UInt> = [125]
        //print(fft.frequencyAtIndex(highpass))
        
        
        // Show the max frequency in real time.
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            mfi = fft.maxFrequencyIndex
            
            if (mfi>highpass) {
            
                //print mfi
                print(mfi)
                
                if self.timerSet == 0 {
                    
                    //set timer, when timer is over erase the buffer
                    self.timerSet = 1
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "cleanBufferAndCalculateResult", userInfo: nil, repeats: false)
                    
                }
                
                //write to maxFrequency buffer
                self.buffer.append(mfi)
                
                //write to fftData buffer
                for i in 0..<windowSize {
                    
                    self.tempArray.append(Double(fft.fftData[i]))
                    
                }
                
                self.fftbuffer.append(self.tempArray)
                
                //write to 1200 magnitude buffer
                self.buffer1200.append(10*log10(self.tempArray[1200]))
                
            }
            
            //self.resultLabel.text = "\(fft.maxFrequencyIndex) (index)\n2\n3\n4\n5\n6\n7\n8\n9\n10"
            //self.audioPlotTime.updateBuffer(buffer[0], withBufferSize: bufferSize);
            
        });
    }
    
    //When the timer is over, call this function to hide the nameLabel
    func cleanBufferAndCalculateResult() {
        
        //print buffer
        print(self.buffer)
        
        //calculate result
        self.result = classifier(buffer)
        
        //print result to log
        print("Result: \(self.result)\n")
        
        //print to screen
        self.printresult()
        
        //clean buffer
        buffer.removeAll()
        
        //clean buffer1200
        buffer1200.removeAll()
        
        //timer flag reset
        self.timerSet = 0
        
        //reset temp array
        self.tempArray = []
        
        //calculate fftplot
        var sum1 = 0.0
        
//        for j in 0..<windowSize {
//            
//            for i in 0..<fftbuffer.count {
//                
//                sum1 += fftbuffer[i][j]
//                
//            }
//            
//            avgfftdata.append(sum1/Double(fftbuffer.count))
//            sum1 = 0.0
//            
//        }
        
        //print fftPlot
//        self.drawFFT(avgfftdata)
        
        //reset fftbuffer and avgfftdata
        fftbuffer = []
        avgfftdata = []
    
    }
    
    func drawFFT(fft: [Double]) {
        
        print("drawFFT")
        
        let dataPoints = fft
        
        var dataEntries: [BarChartDataEntry] = []
        
        var xValues: [String] = []
        
        print(dataPoints[windowSize-1])
        
        let startPoint = 400
        
        let endPoint = 1600
        
        for i in startPoint..<endPoint {
            
            let dataEntry = BarChartDataEntry(value: 100+10*log10(dataPoints[i]), xIndex: i-startPoint)
            
            dataEntries.append(dataEntry)
            
            xValues.append("\(i)")
        }
        
        let chartDataSet = BarChartDataSet(yVals: dataEntries, label: "dB")
        
        chartDataSet.colors = [UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)]
        
        fftPlot.xAxis.labelPosition = .Bottom
        
        fftPlot.data = BarChartData(xVals: xValues, dataSet: chartDataSet)

    }
    
    func classifier(buffer: [UInt]) -> String {
        
        //calculate result from the buffer
        var isGreen = 0
        
        for x in buffer {
            
            if self.greenmfi.contains(x) {
                
                isGreen += 1
                
            }
            
        }
        
        //calculate the 1200th frequency magnitude
        //print("1200th magnitude: \(self.buffer1200)")
        
        let isGreenRatio = Double(isGreen) / Double(buffer.count)
        
        //print("isGreenRatio = \(isGreenRatio)\n")

        if ( !self.whitemfi.isDisjointWith(buffer) ) {
            
            return "white"
            
        } else if ( isGreenRatio >= 0.3 ) {
            
            return "green"
            
        } else if !self.bluemfi.isDisjointWith(buffer)  {
            
            return "blue"
            
        } else {
            
            return "Unknown"
            
        }
        
    }
    
    func setmfi() {
        
        for i in 700..<730 {
            
            bluemfi.insert(UInt(i))
            
        }
        
        for i in 800..<860 {
            
            bluemfi.insert(UInt(i))
            
        }
        
        for i in 786..<789 {
            
            bluemfi.insert(UInt(i))
            
        }
        
        for i in 1000..<1200 {
            
            bluemfi.insert(UInt(i))
            
        }
        
        for i in 740..<770 {
            
            greenmfi.insert(UInt(i))
            
        }
        
        for i in 770..<780 {
            
            whitemfi.insert(UInt(i))
            
        }
        
        for i in 890..<900 {
            
            whitemfi.insert(UInt(i))
            
        }
        
        //        for i in 870..<880 {
        //
        //            greenmfi.insert(UInt(i))
        //
        //        }

        
    }

    func printresult() {
        
        self.resultLabel.text = "\(buffer)\nResult: \(self.result)"
        
    }
    
}