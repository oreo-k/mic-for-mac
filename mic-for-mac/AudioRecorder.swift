import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    private var recordingURL: URL?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default)
            try audioSession?.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
        recordingURL = audioFilename
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Could not start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    func getAudioFileURL() -> URL? {
        return recordingURL
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.temporaryDirectory
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording finished unsuccessfully")
        }
    }
} 