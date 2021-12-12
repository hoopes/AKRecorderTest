//
//  ContentView.swift
//  AKRecorderTest
//
//  Created by Matthew Hoopes on 12/8/21.
//

import AudioKit
import AudioKitEX
import AVFoundation
import SwiftUI

struct RecorderData {
  var isRecording = false
  var isPlayingInput = false
  var isPlayingRecording = false
}

class RecorderConductor: ObservableObject {
  let engine = AudioEngine()
  var inputPlayer = AudioPlayer()
  var recorder: NodeRecorder?
  let recordingPlayer = AudioPlayer()
  let mixer = Mixer()

  // Two example input audio files, different formats
  let mp3Url = Bundle.main.url(forResource: "alphabet", withExtension: "mp3")
  let wavUrl = Bundle.main.url(forResource: "alphabet", withExtension: "wav")

  @Published var data = RecorderData() {
    didSet {
      if data.isRecording {
        NodeRecorder.removeTempFiles()
        do {
          try recorder?.record()
        } catch let err {
          print(err)
        }
      } else {
        if let rec = recorder {
          if rec.isRecording {
            recorder?.stop()

            print ("*** Created file: \(recorder?.audioFile?.url)")
          }
        }
      }

      if data.isPlayingInput {
        if !inputPlayer.isPlaying {
          inputPlayer.play()
        }
      }
      else {
        if inputPlayer.isPlaying {
          inputPlayer.stop()
        }
      }

      if data.isPlayingRecording {
        if let file = recorder?.audioFile {
          recordingPlayer.file = file
          recordingPlayer.play()
        }
      } else {
        if recordingPlayer.isPlaying {
          recordingPlayer.stop()
        }
      }
    }
  }

  init() {

    // Set up an AudioPlayer with a file from disk
    try! inputPlayer.load(url: mp3Url!)
//    try! inputPlayer.load(url: wavUrl!)
    inputPlayer.isLooping = true

    /// ------ Snip from test (https://github.com/AudioKit/AudioKit/blob/main/Tests/AudioKitTests/Extension%20Tests/AVAudioPCMBufferTests.swift#L20)
    let fm = FileManager.default
    let filename = UUID().uuidString + ".m4a"
    let outfileUrl = fm.temporaryDirectory.appendingPathComponent(filename)

    var settings = Settings.audioFormat.settings
    settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
    settings[AVLinearPCMIsNonInterleaved] = NSNumber(value: false)

    let outFile = try! AVAudioFile(
      forWriting: outfileUrl,
      settings: settings)

    recorder = try! NodeRecorder(node: inputPlayer, file: outFile)
    /// ------ End snip from test

    mixer.addInput(inputPlayer)
    mixer.addInput(recordingPlayer)
    engine.output = mixer
  }

  func start() {
    do {
      try engine.start()
    } catch let err {
      print(err)
    }
  }

  func stop() {
    engine.stop()
  }
}

struct ContentView: View {
  @StateObject var conductor = RecorderConductor()

  var body: some View {
    VStack {
      Spacer()
      Text(conductor.data.isPlayingInput ? "STOP INPUT" : "PLAY INPUT").onTapGesture {
        self.conductor.data.isPlayingInput.toggle()
      }
      Spacer()
      Text(conductor.data.isRecording ? "STOP RECORDING" : "RECORD").onTapGesture {
        self.conductor.data.isRecording.toggle()
      }
      Spacer()
      Text(conductor.data.isPlayingRecording ? "STOP" : "PLAY RECORDING").onTapGesture {
        self.conductor.data.isPlayingRecording.toggle()
      }
      Spacer()
    }

    .padding()
    .navigationBarTitle(Text("Recorder"))
    .onAppear {
      self.conductor.start()
    }
    .onDisappear {
      self.conductor.stop()
    }
  }
}
