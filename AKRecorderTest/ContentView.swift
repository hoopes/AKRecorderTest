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

class RecorderConductor: ObservableObject {

  init() {
    NodeRecorder.removeTempFiles() // just make sure the temp dir exists

    let mp3Url = Bundle.main.url(forResource: "alphabet", withExtension: "mp3")!
    let player = AudioPlayer(url: mp3Url)!

    let engine = AudioEngine()
    engine.output = player
    try! engine.start()
    player.play()

    let fm = FileManager.default
    let filename = UUID().uuidString + ".m4a"
    let outfileUrl = fm.temporaryDirectory.appendingPathComponent(filename)

    var settings = Settings.audioFormat.settings
    settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
    settings[AVLinearPCMIsNonInterleaved] = NSNumber(value: false)

    let outFile = try! AVAudioFile(
      forWriting: outfileUrl,
      settings: settings)

    let recorder = try! NodeRecorder(node: player, file: outFile)
    try! recorder.record()

    sleep(2)

    recorder.stop()
    engine.stop()

    print ("*** Created m4a file: \(recorder.audioFile?.url)")
  }
}

struct ContentView: View {

  let conductor = RecorderConductor()

  var body: some View {
    VStack {
      Text("Hello World")
    }

    .padding()
    .navigationBarTitle(Text("Recorder"))
  }
}
