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
        
        NodeRecorder.removeRecordedFiles() // just make sure the temp dir exists
        
        let inputFileURL = Bundle.main.url(forResource: "TestResources/12345", withExtension: "wav")!
        
        assert(FileManager.default.fileExists(atPath: inputFileURL.path),
               "inputFileURL does not exist")
        
        let fm = FileManager.default
        let filename = UUID().uuidString + ".m4a"
        let outputFileURL = fm.temporaryDirectory.appendingPathComponent(filename)
        
        // MARK: Begin Separate Code Block or Function for Recording
        if true {
            let player = AudioPlayer(url: inputFileURL)!
            
            let engine = AudioEngine()
            engine.output = player
            try! engine.start()
            
            player.play()
            
            var settings = Settings.audioFormat.settings
            settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
            settings[AVLinearPCMIsNonInterleaved] = NSNumber(value: false)
            
            var outFile: AVAudioFile
            do {
                outFile = try AVAudioFile(forWriting: outputFileURL, settings: settings)
            } catch {
                assertionFailure("could not create outFile: \(error.localizedDescription)")
                fatalError()
            }
            
            assert(FileManager.default.fileExists(atPath: outFile.url.path),
                   "outFile does not exist")
            
            var recorder: NodeRecorder
            do {
                recorder = try NodeRecorder(node: player, file: outFile)
            } catch {
                assertionFailure("could not create recorder: \(error.localizedDescription)")
                fatalError()
            }
            
            do {
                try recorder.record()
            } catch {
                assertionFailure("could not run recorder.record(): \(error.localizedDescription)")
            }
            
            sleep(6) // a little longer than 2 seconds to allow some wiggle room
            
            player.stop()
            recorder.stop()
            engine.stop()
        }
        // MARK: End Separate Code Block or Function for Recording
        
        var successFile: AVAudioFile
        do {
            // This file is ok to read when the recorder is done
            // But don't try to do anything with the same file that was meant forWriting
            successFile = try AVAudioFile(forReading: outputFileURL)
        } catch {
            assertionFailure("could not create successFile: \(error.localizedDescription)")
            fatalError()
        }
        
        assert(successFile.length > 0, "successFile length is not > 0")
        // This is still accessing the file meant for writing from the recorder
        // That's why it's commented out now
        //print ("*** Created m4a file?: \(recorder.audioFile?.url)")
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
