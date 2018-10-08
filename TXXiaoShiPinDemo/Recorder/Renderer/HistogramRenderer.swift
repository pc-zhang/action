//
//  RosyWriterCIFilterRenderer.swift
//  RosyWriter
//
//  Translated by OOPer in cooperation with shlab.jp,  on 2015/1/12.
//
//
//
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 The RosyWriter CoreImage CIFilter-based effect renderer
 */

import UIKit
import CoreMedia
import CoreVideo

@objc(HistogramRenderer)
class HistogramRenderer: NSObject, RosyWriterRenderer {
    let avaliableFilters = CoreImageFilters.avaliableFilters()

    private var _ciContext: CIContext!
    private var _rosyFilter: CIFilter!
    private var _rgbColorSpace: CGColorSpace!
    private var _bufferPool: CVPixelBufferPool!
    private var _bufferPoolAuxAttributes: NSDictionary = [:]
    private var _outputFormatDescription: CMFormatDescription!
    private var _histogram: [[vImagePixelCount]]
    
    //MARK: API
    
    init(_ histogram: [[vImagePixelCount]]) {
        _histogram = histogram
    }
    
    deinit {
        self.deleteBuffers()
    }
    
    //MARK: RosyWriterRenderer
    
    let operatesInPlace: Bool = false
    
    let inputPixelFormat: FourCharCode = kCVPixelFormatType_32BGRA
        
    func changeFilter(_ index: Int) {
        if let newFilter = CIFilter(name: avaliableFilters[index]) {
            _rosyFilter = newFilter
        }
    }
    
    func prepareForInputWithFormatDescription(_ inputFormatDescription: CMFormatDescription!, outputRetainedBufferCountHint: Int) {
        // The input and output dimensions are the same. This renderer doesn't do any scaling.
        let dimensions = CMVideoFormatDescriptionGetDimensions(inputFormatDescription)
        
        self.deleteBuffers()
        if !self.initializeBuffersWithOutputDimensions(dimensions, retainedBufferCountHint: outputRetainedBufferCountHint) {
            fatalError("Problem preparing renderer.")
        }
        
        _rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let eaglContext = EAGLContext(api: .openGLES2)
        _ciContext = CIContext(eaglContext: eaglContext!, options: [CIContextOption.workingColorSpace : NSNull()])
        
        _rosyFilter = CIFilter(name: "CIColorMatrix")
        let greenCoefficients: [CGFloat] = [0, 0, 0, 0]
        _rosyFilter.setValue(CIVector(values: greenCoefficients, count: 4), forKey: "inputGVector")
    }
    
    func reset() {
        self.deleteBuffers()
    }
    
    func copyRenderedPixelBuffer(_ pixelBuffer: CVPixelBuffer!) -> CVPixelBuffer! {
        var renderedOutputPixelBuffer: CVPixelBuffer? = nil
        
        let err = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _bufferPool, &renderedOutputPixelBuffer)
        if err != 0 {
            NSLog("Cannot obtain a pixel buffer from the buffer pool (%d)", Int(err))
        } else {
            var immutableHistogram: [UnsafePointer<vImagePixelCount>?] = _histogram.map {
                return UnsafePointer<vImagePixelCount>($0)
            }
            
            
            var buffer = vImage_Buffer()
            buffer.data = CVPixelBufferGetBaseAddress(pixelBuffer)
            buffer.rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
            buffer.width = vImagePixelCount(CVPixelBufferGetWidth(pixelBuffer))
            buffer.height = vImagePixelCount(CVPixelBufferGetHeight(pixelBuffer))
            
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageByteOrderInfo.orderMask.rawValue | CGImageAlphaInfo.last.rawValue)
            
            var cgFormat = vImage_CGImageFormat(bitsPerComponent: 8,
                                                bitsPerPixel: 32,
                                                colorSpace: nil,
                                                bitmapInfo: bitmapInfo,
                                                version: 0,
                                                decode: nil,
                                                renderingIntent: .defaultIntent)
            
            
            var error = vImageBuffer_InitWithCVPixelBuffer(&buffer, &cgFormat, pixelBuffer, nil, nil, vImage_Flags(kvImageNoFlags))
            assert(kvImageNoError == error)
            defer {
                free(buffer.data)
            }
            
//            error = vImageHistogramSpecification_ARGB8888(&buffer,
//                                                              &buffer,
//                                                              &immutableHistogram,
//                                                              vImage_Flags(kvImageLeaveAlphaUnchanged))
//
//            guard error == kvImageNoError else {
//                return renderedOutputPixelBuffer
//            }
            
            let outputCVImageFormat = vImageCVImageFormat_CreateWithCVPixelBuffer(pixelBuffer).takeRetainedValue()
            vImageCVImageFormat_SetColorSpace(outputCVImageFormat,
                                              CGColorSpaceCreateDeviceRGB())
            
            error = vImageBuffer_CopyToCVPixelBuffer(&buffer,
                                                     &cgFormat,
                                                     renderedOutputPixelBuffer!,
                                                     outputCVImageFormat,
                                                     nil,
                                                     vImage_Flags(kvImageNoFlags))
            
            guard error == kvImageNoError else {
                return renderedOutputPixelBuffer
            }
            
            
        }
        
        return renderedOutputPixelBuffer
    }

    
    var outputFormatDescription: CMFormatDescription? {
        return _outputFormatDescription
    }
    
    //MARK: Internal
    
    private func initializeBuffersWithOutputDimensions(_ outputDimensions: CMVideoDimensions, retainedBufferCountHint clientRetainedBufferCountHint: size_t) -> Bool
    {
        var success = true
        
        let maxRetainedBufferCount = clientRetainedBufferCountHint
        _bufferPool = createPixelBufferPool(outputDimensions.width, outputDimensions.height, kCVPixelFormatType_32BGRA, maxRetainedBufferCount.i)
        if _bufferPool == nil {
            NSLog("Problem initializing a buffer pool.")
            success = false
        } else {
            
            _bufferPoolAuxAttributes = createPixelBufferPoolAuxAttributes(maxRetainedBufferCount.i)
            preallocatePixelBuffersInPool(_bufferPool, _bufferPoolAuxAttributes)
            
            var outputFormatDescription: CMFormatDescription? = nil
            var testPixelBuffer: CVPixelBuffer? = nil
            CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, _bufferPool, _bufferPoolAuxAttributes, &testPixelBuffer)
            if testPixelBuffer == nil {
                NSLog("Problem creating a pixel buffer.")
                success = false
            } else {
                CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: testPixelBuffer!, formatDescriptionOut: &outputFormatDescription)
                _outputFormatDescription = outputFormatDescription
            }
        }
        
        if !success {
            self.deleteBuffers()
        }
        return success
    }
    
    private func deleteBuffers() {
        if _bufferPool != nil {
            _bufferPool = nil
        }
        _bufferPoolAuxAttributes = [:]
        if _outputFormatDescription != nil {
            _outputFormatDescription = nil
        }
        if _rgbColorSpace != nil {
            _rgbColorSpace = nil
        }
        
        _ciContext = nil
        _rosyFilter = nil
    }
}

private func createPixelBufferPool(_ width: Int32, _ height: Int32, _ pixelFormat: OSType, _ maxBufferCount: Int32) -> CVPixelBufferPool?
{
    var outputPool: CVPixelBufferPool? = nil
    
    let sourcePixelBufferOptions: NSDictionary = [kCVPixelBufferPixelFormatTypeKey : pixelFormat,
        kCVPixelBufferWidthKey : width,
        kCVPixelBufferHeightKey : height,
        kCVPixelFormatOpenGLESCompatibility : true,
        kCVPixelBufferIOSurfacePropertiesKey : NSDictionary()]
    
    let pixelBufferPoolOptions: NSDictionary = [kCVPixelBufferPoolMinimumBufferCountKey : maxBufferCount]
    
    CVPixelBufferPoolCreate(kCFAllocatorDefault, pixelBufferPoolOptions, sourcePixelBufferOptions, &outputPool)
    
    return outputPool
}

private func createPixelBufferPoolAuxAttributes(_ maxBufferCount: Int32) -> NSDictionary {
    // CVPixelBufferPoolCreatePixelBufferWithAuxAttributes() will return kCVReturnWouldExceedAllocationThreshold if we have already vended the max number of buffers
    let auxAttributes: NSDictionary = [kCVPixelBufferPoolAllocationThresholdKey : maxBufferCount]
    return auxAttributes
}

private func preallocatePixelBuffersInPool(_ pool: CVPixelBufferPool, _ auxAttributes: NSDictionary) {
    // Preallocate buffers in the pool, since this is for real-time display/capture
    var pixelBuffers: [CVPixelBuffer] = []
    while true {
        var pixelBuffer: CVPixelBuffer? = nil
        let err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer)
        
        if err == kCVReturnWouldExceedAllocationThreshold {
            break
        }
        assert(err == noErr)
        pixelBuffers.append(pixelBuffer!)
    }
    pixelBuffers.removeAll()
}
