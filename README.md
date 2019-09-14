# RxJellySlider

This is the RX Version of JellySlider compatible with swift 5 with cool new Features


## Added Features:
- set progressValue programatically
- integrated with RxSwift to bind with your observable<Float>

[![CI Status](http://img.shields.io/travis/popwarsweet/JellySlider.svg?style=flat)](https://travis-ci.org/popwarsweet/JellySlider)
[![Version](https://img.shields.io/cocoapods/v/JellySlider.svg?style=flat)](http://cocoapods.org/pods/JellySlider)
[![License](https://img.shields.io/cocoapods/l/JellySlider.svg?style=flat)](http://cocoapods.org/pods/JellySlider)
[![Platform](https://img.shields.io/cocoapods/p/JellySlider.svg?style=flat)](http://cocoapods.org/pods/JellySlider)

A fun replacement for UISlider. The slider uses bezier paths within a CAShapeLayer for the track and slider knob, Sprite Kit for particles, and force touch for expanding the knob when force on the screen changes.

## Demo
<img src="https://github.com/popwarsweet/JellySlider/blob/master/demo.gif" width="600">

## Example

__usage:__
```swift
...

let slider = JellySlider(frame: sliderContaier.bounds)
myFloatDriver.drive(slider.rx.value).disposed(by: disposeBag)

...

```

## Installation

Drag and drop Following files from `JellySlider+BEKApps` in your Xcode Project:

- JellySlider.swift
- JellySlider+Rx.swift
- SplashParticle.sks
- spark.png

## Author
Behrad Kazemi, Behradkzm@gmail.com, bekapps.com

Many thanks to Kyle Zaragoza

## License

JellySlider is available under the MIT license. See the LICENSE file for more info.
