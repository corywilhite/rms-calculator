//
//  rms_calculator.swift
//
//  Created by Cory Wilhite on 1/26/20.
//  Copyright © 2020 Cory Wilhite. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate

///
/// Takes a folder of .wav files and calculates the Root Mean Square (RMS) information.
/// Outputs the RMS info to a .csv file
///
/// Example Usage:
/// `swift ~/Desktop/rms_calculator.swift --path ~/Desktop/samples/ --output RMSSampleInfo`
///
/// --path Expects the path to your folder of .wav samples
/// --output Expects a file name for the .csv file that will be output to your current user Desktop


struct RMSInfo {
  let fileName: String
  let rawRMS: Float
  let RMS_dBFS: Float

  static let csvHeaderString = "File Name,Raw RMS,RMS dBFS"

  func toCSVString() -> String {
    return "\(fileName),\(rawRMS),\(RMS_dBFS)"
  }
}

// MARK: - Load Wav URLS from command line argument

func loadWavURLS() -> [URL] {
  guard let pathFlagIndex = CommandLine.arguments.firstIndex(of: "--path") else {
    fatalError("Need to pass in a directory for --path")
  }
  let path = NSString(string: CommandLine.arguments[pathFlagIndex + 1]).expandingTildeInPath
  let pathURL = URL(fileURLWithPath: path, isDirectory: true)
  guard let enumerator = FileManager.default.enumerator(at: pathURL, includingPropertiesForKeys: nil) else {
    fatalError("failed to load path")
  }

  var wavFiles: [URL] = []
  for case let fileURL as URL in enumerator {
    if fileURL.pathExtension == "wav" {
      wavFiles.append(fileURL)
    }
  }

  return wavFiles
}

// MARK: - Load csv output path

func loadCSVOutputPath() -> URL {
  guard let outputFlagIndex = CommandLine.arguments.firstIndex(of: "--output") else {
    fatalError("Need to pass in a name for the output file. Exclude .csv from the output file name")
  }
  let file = CommandLine.arguments[outputFlagIndex + 1]
  return URL(fileURLWithPath: file)
}

// MARK: - Process each wav and extract RMS value

func getTotalSampleBuffer(filePath: URL) -> [Float] {
  guard let file = try? AVAudioFile(forReading: filePath) else {
    fatalError("Unable to read file at path \(filePath)")
  }
  guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 1024) else {
    fatalError("Failed to create PCM buffer from wav file")
  }

  var totalBuffer: [Float] = []
  while file.framePosition < file.length {
    do { try file.read(into: buffer) }
    catch { fatalError("Failed reading into the established pcm buffer for file \(file)") }
    let bufferPointer = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))
    let bufferArray = Array(bufferPointer)
    totalBuffer += bufferArray
  }

  return totalBuffer
}

func calculateRMSValue(samples: [Float]) -> Float {
  var c: Float = .nan
  vDSP_rmsqv(samples,
             vDSP_Stride(1),
             &c,
             vDSP_Length(samples.count))
  return c
}

func convertToDbfs(_ sample: Float) -> Float {
  return Float(20.0)*log10(abs(sample))
}

// MARK: - Main


let urls = loadWavURLS()

var rmsInfoArray: [RMSInfo] = []

for url in urls {
  let fileName = url.lastPathComponent
  print("File: \(url)")

  let totalSampleBuffer = getTotalSampleBuffer(filePath: url)
  let rmsValue = calculateRMSValue(samples: totalSampleBuffer)
  let dbfsRmsValue = convertToDbfs(rmsValue)

  print("RMS: \(rmsValue)")
  print("RMS dBFS: \(dbfsRmsValue)\n")

  let rmsInfo = RMSInfo(
    fileName: fileName,
    rawRMS: rmsValue,
    RMS_dBFS: dbfsRmsValue
  )

  rmsInfoArray.append(rmsInfo)
}

var csvFileContent = RMSInfo.csvHeaderString + "\n"

for rmsInfo in rmsInfoArray {
  csvFileContent += rmsInfo.toCSVString()
  csvFileContent += "\n"
}

print("CSV file content\n\(csvFileContent)")
let csvOutputPath = loadCSVOutputPath()
print("Saving to file at path: \(csvOutputPath)")

do {
  if FileManager.default.fileExists(atPath: csvOutputPath.absoluteString) {
    print("Remove file")
    try FileManager.default.removeItem(atPath: csvOutputPath.absoluteString)
  }
  guard let contents = csvFileContent.data(using: .utf8) else {
    fatalError("Failed to convert CSV content string to Data")
  }
  try contents.write(to: csvOutputPath)
} catch {
  print("Failed to write content to a .csv file at \(csvOutputPath) \(error)")
}
