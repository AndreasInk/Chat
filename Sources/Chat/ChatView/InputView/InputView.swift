//
//  InputView.swift
//  Chat
//
//  Created by Alex.M on 25.05.2022.
//

import SwiftUI
import MediaPicker

public enum InputViewStyle {
    case message
    case signature

    var placeholder: String {
        switch self {
        case .message:
            return "Type a message..."
        case .signature:
            return "Add signature..."
        }
    }
}

public enum InputViewAction {
    case photo
    case add
    case camera
    case send

    case recordAudioHold
    case recordAudioTap
    case recordAudioLock
    case stopRecordAudio
    case deleteRecord
    case playRecord
    case pauseRecord
    //    case location
    //    case document
}

public enum InputViewState {
    case empty
    case hasTextOrMedia
    case isRecordingHold
    case isRecordingTap
    case hasRecording
    case playingRecording
    case pausedRecording

    var canSend: Bool {
        switch self {
        case .hasTextOrMedia, .hasRecording, .isRecordingTap, .playingRecording, .pausedRecording: return true
        default: return false
        }
    }
}

public struct InputViewAttachments {
    public var text: String = ""
    public var medias: [Media] = []
    public var recording: Recording?
    public var replyMessage: ReplyMessage?
}

public struct Recording {
    public var duration: Double = 0.0
    public var waveformSamples: [CGFloat] = []
    public var url: URL?
}

struct InputView: View {

    @Environment(\.chatTheme) private var theme

    @ObservedObject var viewModel: InputViewModel
    let style: InputViewStyle
    let messageUseMarkdown: Bool

    private var onAction: (InputViewAction) -> Void {
        viewModel.inputViewAction()
    }

    private var state: InputViewState {
        viewModel.state
    }

    @ObservedObject var recordPlayer = RecordingPlayer.shared

    @State private var overlaySize: CGSize = .zero

    @State private var recordButtonFrame: CGRect = .zero
    @State private var lockRecordFrame: CGRect = .zero
    @State private var deleteRecordFrame: CGRect = .zero

    @State private var dragStart: Date?

    var body: some View {
        VStack {
            viewOnTop
            HStack(alignment: .bottom, spacing: 10) {
                HStack(alignment: .bottom, spacing: 0) {
                    leftView
                    middleView
                    rightView
                }
                .background {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(backgroundColor)
                }

                rigthOutsideButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    var leftView: some View {
        if [.isRecordingTap, .isRecordingHold, .hasRecording, .playingRecording, .pausedRecording].contains(state) {
            deleteRecordButton
        } else {
            switch style {
            case .message:
                attachButton
            case .signature:
                addButton
            }
        }
    }

    @ViewBuilder
    var middleView: some View {
        Group {
            switch state {
            case .hasRecording, .playingRecording, .pausedRecording:
                recordWaveform
            case .isRecordingHold:
                swipeToCancel
            case .isRecordingTap:
                Spacer()
            default:
                TextInputView(text: $viewModel.attachments.text, style: style)
            }
        }
        .frame(minHeight: 48)
    }

    @ViewBuilder
    var rightView: some View {
        Group {
            switch state {
            case .empty:
                cameraButton
            case .isRecordingHold, .isRecordingTap:
                recordDurationInProcess
            case .hasRecording:
                recordDuration
            case .playingRecording, .pausedRecording:
                recordDurationLeft
            default:
                EmptyView()
            }
        }
        .frame(minHeight: 48)
    }

    @ViewBuilder
    var rigthOutsideButton: some View {
        ZStack {
            if [.isRecordingTap, .isRecordingHold].contains(state) {
                RecordIndicator()
                    .viewSize(80)
                    .foregroundColor(theme.colors.sendButtonBackground)
            }
            Group {
                if state.canSend {
                    sendButton
                } else {
                    recordButton
                        .highPriorityGesture(dragGesture())
                }
            }
            .compositingGroup()
            .overlay(alignment: .top) {
                Group {
                    if state == .isRecordingTap {
                        stopRecordButton
                            .sizeGetter($overlaySize)
                    } else if state == .isRecordingHold {
                        lockRecordButton
                            .sizeGetter($overlaySize)
                    }
                }
                .offset(y: -overlaySize.height - 24)
            }
        }
        .viewSize(48)
    }

    @ViewBuilder
    var viewOnTop: some View {
        if let message = viewModel.attachments.replyMessage {
            VStack(spacing: 8) {
                Rectangle()
                    .foregroundColor(theme.colors.friendMessage)
                    .frame(height: 2)

                HStack {
                    theme.images.reply.replyToMessage
                    Capsule()
                        .foregroundColor(theme.colors.myMessage)
                        .frame(width: 2)
                    VStack(alignment: .leading) {
                        Text("Reply to \(message.user.name)")
                            .font(.caption2)
                            .foregroundColor(theme.colors.buttonBackground)
                        textView(message.text)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 2)
                    Spacer()
                    theme.images.reply.cancelReply
                        .onTapGesture {
                            viewModel.attachments.replyMessage = nil
                        }
                }
                .padding(.horizontal, 26)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    func textView(_ text: String) -> some View {
        if messageUseMarkdown,
           let attributed = try? AttributedString(markdown: text) {
            Text(attributed)
        } else {
            Text(text)
        }
    }

    var attachButton: some View {
        Button {
            onAction(.photo)
        } label: {
            theme.images.inputView.attach
                .viewSize(24)
                .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 8))
        }
    }

    var addButton: some View {
        Button {
            onAction(.add)
        } label: {
            theme.images.inputView.add
                .viewSize(24)
                .circleBackground(theme.colors.addButtonBackground)
                .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 8))
        }
    }

    var cameraButton: some View {
        Button {
            onAction(.camera)
        } label: {
            theme.images.inputView.attachCamera
                .viewSize(24)
                .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 12))
        }
    }

    var sendButton: some View {
        Button {
            onAction(.send)
        } label: {
            theme.images.inputView.arrowSend
                .viewSize(48)
                .circleBackground(theme.colors.sendButtonBackground)
        }
    }

    var recordButton: some View {
        theme.images.inputView.microphone
            .viewSize(48)
            .circleBackground(theme.colors.sendButtonBackground)
            .frameGetter($recordButtonFrame)
    }

    var deleteRecordButton: some View {
        Button {
            onAction(.deleteRecord)
        } label: {
            theme.images.recordAudio.deleteRecord
                .viewSize(24)
                .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 8))
        }
        .frameGetter($deleteRecordFrame)
    }

    var stopRecordButton: some View {
        Button {
            onAction(.stopRecordAudio)
        } label: {
            theme.images.recordAudio.stopRecord
                .viewSize(28)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.4), radius: 1)
                )
        }
    }

    var lockRecordButton: some View {
        Button {
            onAction(.recordAudioLock)
        } label: {
            VStack(spacing: 20) {
                theme.images.recordAudio.lockRecord
                theme.images.recordAudio.sendRecord
            }
            .frame(width: 28)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.4), radius: 1)
            )
        }
        .frameGetter($lockRecordFrame)
    }

    var swipeToCancel: some View {
        HStack {
            Spacer()
            Button {
                onAction(.deleteRecord)
            } label: {
                HStack {
                    theme.images.recordAudio.cancelRecord
                    Text("Cancel")
                        .font(.footnote)
                        .foregroundColor(theme.colors.textLightContext)
                }
            }
            Spacer()
        }
    }

    var recordDurationInProcess: some View {
        HStack {
            Circle()
                .foregroundColor(theme.colors.recordDot)
                .viewSize(6)
            recordDuration
        }
    }

    var recordDuration: some View {
        Text(DateFormatter.timeString(Int(viewModel.attachments.recording?.duration ?? 0)))
            .foregroundColor(theme.colors.textLightContext)
            .opacity(0.6)
            .font(.caption2)
            .monospacedDigit()
            .padding(.trailing, 12)
    }

    var recordDurationLeft: some View {
        Text(DateFormatter.timeString(Int(RecordingPlayer.shared.secondsLeft)))
            .foregroundColor(theme.colors.textLightContext)
            .opacity(0.6)
            .font(.caption2)
            .monospacedDigit()
            .padding(.trailing, 12)
    }

    var playRecordButton: some View {
        Button {
            onAction(.playRecord)
        } label: {
            theme.images.recordAudio.playRecord
        }
    }

    var pauseRecordButton: some View {
        Button {
            onAction(.pauseRecord)
        } label: {
            theme.images.recordAudio.pauseRecord
        }
    }

    @ViewBuilder
    var recordWaveform: some View {
        if let samples = viewModel.attachments.recording?.waveformSamples {
            HStack(spacing: 8) {
                Group {
                    if state == .hasRecording || state == .pausedRecording {
                        playRecordButton
                    } else if state == .playingRecording {
                        pauseRecordButton
                    }
                }
                .frame(width: 20)

                RecordWaveformPlaying(samples: samples, progress: recordPlayer.progress, color: theme.colors.textLightContext, addExtraDots: true)
            }
            .padding(.horizontal, 8)
        }
    }

    var backgroundColor: Color {
        switch style {
        case .message:
            return theme.colors.inputLightContextBackground
        case .signature:
            return theme.colors.inputDarkContextBackground
        }
    }

    @State private var tapDelayTimer: Timer?
    let tapDelay = 0.2
    func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
            .onChanged { _ in
                if dragStart == nil {
                    dragStart = Date()
                    tapDelayTimer = Timer.scheduledTimer(withTimeInterval: tapDelay, repeats: false) { _ in
                        if state != .isRecordingTap {
                            self.onAction(.recordAudioHold)
                        }
                    }
                }
            }
            .onEnded() { value in
                tapDelayTimer = nil
                if recordButtonFrame.contains(value.location) {
                    if let dragStart = dragStart, Date().timeIntervalSince(dragStart) < tapDelay {
                        onAction(.recordAudioTap)
                    } else {
                        onAction(.send)
                    }
                }
                else if lockRecordFrame.contains(value.location) {
                    onAction(.recordAudioLock)
                }
                else if deleteRecordFrame.contains(value.location) {
                    onAction(.deleteRecord)
                } else {
                    onAction(.send)
                }
                dragStart = nil
            }
    }
}