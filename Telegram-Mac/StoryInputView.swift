//
//  StoryInputView.swift
//  Telegram
//
//  Created by Mike Renoir on 25.04.2023.
//  Copyright © 2023 Telegram. All rights reserved.
//

import Foundation
import TGUIKit
import TGModernGrowingTextView
import SwiftSignalKit
import Postbox
import TelegramCore
import ColorPalette

extension MessageReaction.Reaction {
    static var defaultStoryLike: MessageReaction.Reaction {
        return .builtin("❤️".withoutColorizer)
    }
}

private let placeholderColor = NSColor.white.withAlphaComponent(0.33)

enum StoryInputState : Equatable {
    case focus
    case none
}

protocol StoryInput {
    func setArguments(_ arguments: StoryArguments?, groupId: PeerId?) -> Void
    func updateState(_ state: StoryInteraction.State, animated: Bool) -> Void
    func updateInputText(_ state: ChatTextInputState, prevState: ChatTextInputState, animated: Bool) -> Void
    func updateInputState(animated: Bool)
    func installInputStateUpdate(_ f: ((StoryInputState)->Void)?) -> Void
    func makeUrl()
    func resetInputView()
    func updateInputContext(with result:ChatPresentationInputQueryResult?, context: InputContextHelper, animated:Bool)
    func like(_ like: StoryReactionAction, resetIfNeeded: Bool)

    func update(_ story: StoryContentItem, animated: Bool)
    
    var isFirstResponder: Bool { get }
    var text: TGModernGrowingTextView? { get }
    var input: NSTextView? { get }
}
private var send_image: CGImage {
    NSImage(named: "Icon_SendMessage")!.precomposed(storyTheme.colors.accent)
}
private var send_image_active: CGImage {
    NSImage(named: "Icon_SendMessage")!.precomposed(storyTheme.colors.accent.darker())
}

private let like_image: CGImage  = NSImage(named: "Icon_StoryLike")!.precomposed(NSColor(0xffffff, 0.33))
private var like_image_active: CGImage  = NSImage(named: "Icon_StoryLike")!.precomposed(NSColor(0xffffff, 0.53))


private let attach_image: CGImage  = NSImage(named: "Icon_ChatAttach")!.precomposed(NSColor(0xffffff, 0.33))
private let attach_image_active: CGImage  = NSImage(named: "Icon_ChatAttach")!.precomposed(NSColor(0xffffff, 0.53))

private let voice_image: CGImage  = NSImage(named: "Icon_RecordVoice")!.precomposed(NSColor(0xffffff, 0.33))
private let voice_image_active: CGImage  = NSImage(named: "Icon_RecordVoice")!.precomposed(NSColor(0xffffff, 0.53))

private let video_message_image: CGImage  = NSImage(named: "Icon_RecordVideoMessage")!.precomposed(NSColor(0xffffff, 0.33))
private let video_message_image_active: CGImage  = NSImage(named: "Icon_RecordVideoMessage")!.precomposed(NSColor(0xffffff, 0.53))


private let stickers_image: CGImage  = NSImage(named: "Icon_ChatEntertainmentSticker")!.precomposed(NSColor(0xffffff, 0.33))
private var stickers_image_active: CGImage  = NSImage(named: "Icon_ChatEntertainmentSticker")!.precomposed(NSColor(0xffffff, 0.53))

private let emoji_image: CGImage  = NSImage(named: "Icon_Entertainments")!.precomposed(NSColor(0xffffff, 0.33))
private var emoji_image_active: CGImage  = NSImage(named: "Icon_Entertainments")!.precomposed(NSColor(0xffffff, 0.53))



private let story_like: CGImage  = NSImage(named: "Icon_StoryInputLike")!.precomposed(NSColor(0xffffff, 0.33))
private let story_like_active: CGImage  = NSImage(named: "Icon_StoryInputLike")!.precomposed(NSColor(0xffffff, 0.53))

private let share_image: CGImage  = NSImage(named: "Icon_StoryShare")!.precomposed(NSColor(0xffffff, 0.33))
private let share_image_active: CGImage  = NSImage(named: "Icon_StoryShare")!.precomposed(NSColor(0xffffff, 0.53))


private final class StoryLikeActionButton: Control {
    private let control: ImageButton = ImageButton(frame: NSMakeRect(0, 0, 50, 50))
    private var myReaction: MessageReaction.Reaction?
    private var story: StoryContentItem?
    private var state: StoryInteraction.State?
    private var reaction: InlineStickerItemLayer?
    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(control)
        self.layer?.masksToBounds = false
        control.userInteractionEnabled = false
    }
    
    override func stateDidUpdate(_ state: ControlState) {
        control.controlState = state
    }
    
    override var isSelected: Bool {
        didSet {
            control.isSelected = isSelected
        }
    }
    
    func react(_ reaction: StoryReactionAction, state: StoryInteraction.State, context: AccountContext) {
        self.myReaction = reaction.item.reaction
        if let view = self.reaction {
            performSublayerRemoval(view, animated: true, scale: true)
        }
        let layer: InlineStickerItemLayer? = makeView(reaction.item.reaction, state: state, context: context, appear: true)
        if let layer = layer {
            layer.animateAlpha(from: 0, to: 1, duration: 0.2)
            layer.isPlayable = true
        }
        control.isHidden = layer != nil
        self.reaction = layer
        
        
        playReaction(reaction, context: context)
    }
    
    
    func playReaction(_ reaction: StoryReactionAction, context: AccountContext) -> Void {
         
                  
         var file: TelegramMediaFile?
         var effectFileId: Int64?
         var effectFile: TelegramMediaFile?
         switch reaction.item {
         case let .custom(fileId, f):
             file = f
             effectFileId = fileId
         case let .builtin(string):
             let reaction = context.reactions.available?.reactions.first(where: { $0.value.string.withoutColorizer == string.withoutColorizer })
             file = reaction?.selectAnimation
             effectFile = reaction?.aroundAnimation
         }
         
         guard let icon = file else {
             return
         }
                
                 
         let finish:()->Void = { [weak self] in
             
         }
                  
         let play:(NSView, TelegramMediaFile)->Void = { container, icon in
             
             if let effectFileId = effectFileId {
                 let player = CustomReactionEffectView(frame: NSMakeSize(80, 80).bounds, context: context, fileId: effectFileId)
                 player.isEventLess = true
                 player.triggerOnFinish = { [weak player] in
                     player?.removeFromSuperview()
                     finish()
                 }
                 let rect = CGRect(origin: CGPoint(x: (container.frame.width - player.frame.width) / 2, y: (container.frame.height - player.frame.height) / 2), size: player.frame.size)
                 player.frame = rect
                 container.addSubview(player)
                 
             } else if let effectFile = effectFile {
                 let player = InlineStickerItemLayer(account: context.account, file: effectFile, size: NSMakeSize(80, 80), playPolicy: .playCount(1))
                 player.isPlayable = true
                 player.frame = NSMakeRect((container.frame.width - player.frame.width) / 2, (container.frame.height - player.frame.height) / 2, player.frame.width, player.frame.height)
                 
                 container.layer?.addSublayer(player)
                 player.triggerOnState = (.finished, { [weak player] state in
                     player?.removeFromSuperlayer()
                     finish()
                 })
             }
         }
         
         let layer = InlineStickerItemLayer(account: context.account, file: icon, size: NSMakeSize(25, 25))

         let completed: (Bool)->Void = { [weak self]  _ in
             DispatchQueue.main.async {
                 DispatchQueue.main.async {
                     if let container = self {
                         play(container, icon)
                     }
                 }
             }
         }
         if let fromRect = reaction.fromRect {
             let toRect = self.convert(self.frame.size.bounds, to: nil)
             
             let from = fromRect.origin.offsetBy(dx: fromRect.width / 2, dy: fromRect.height / 2)
             let to = toRect.origin.offsetBy(dx: toRect.width / 2, dy: toRect.height / 2)
             parabollicReactionAnimation(layer, fromPoint: from, toPoint: to, window: context.window, completion: completed)
         } else {
             completed(true)
         }
     }
     
    
    
    private func makeView(_ reaction: MessageReaction.Reaction, state: StoryInteraction.State, context: AccountContext, appear: Bool = false) -> InlineStickerItemLayer? {
        let layer: InlineStickerItemLayer?
        let size = NSMakeSize(25, 25)
        switch reaction {
        case let .custom(fileId):
            layer = .init(account: context.account, inlinePacksContext: context.inlinePacksContext, emoji: .init(fileId: fileId, file: nil, emoji: ""), size: size, playPolicy: .onceEnd)
        case .builtin:
            if let animation = state.reactions?.reactions.first(where: { $0.value == reaction }) {
                let file = appear ? animation.activateAnimation : animation.selectAnimation
                layer = InlineStickerItemLayer(account: context.account, file: file, size: size, playPolicy: .onceEnd)
            } else {
                layer = nil
            }
        }
        if let layer = layer {
            layer.frame = focus(size)
            self.layer?.addSublayer(layer)
            layer.isPlayable = false
        }
        return layer
    }
    
    func update(_ story: StoryContentItem, state: StoryInteraction.State, context: AccountContext, animated: Bool) {
        self.story = story
        self.state = state
        guard let state = self.state else {
            return
        }
        
        if let reaction = story.storyItem.myReaction, !state.inputInFocus {
            if self.myReaction != reaction {
                if let view = self.reaction {
                    performSublayerRemoval(view, animated: animated, scale: true)
                }
                let layer: InlineStickerItemLayer? = makeView(reaction, state: state, context: context)
                
                if let layer = layer {
                    if animated {
                        layer.animateAlpha(from: 0, to: 1, duration: 0.2)
                    }
                }
                self.reaction = layer
            }
            self.myReaction = story.storyItem.myReaction
        } else if let view = reaction {
            performSublayerRemoval(view, animated: animated)
            self.reaction = nil
            self.myReaction = nil
        }
        
        if state.inputInFocus {
            control.set(image: state.emojiState == .emoji ? emoji_image : stickers_image, for: .Normal)
            control.set(image: state.emojiState == .emoji ? emoji_image_active : stickers_image_active, for: .Highlight)
        } else {
            control.set(image: like_image, for: .Normal)
            control.set(image: like_image_active, for: .Highlight)
        }
        control.isHidden = self.reaction != nil
        
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class StoryReplyActionButton : View {
    
    enum State : Equatable {
        case empty(isVoice: Bool)
        case text
        case share
    }
    
    private var current: ImageButton?
    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private var state: State?
    private var story: StoryContentItem?
    func update(state: State, arguments: StoryArguments, story: StoryContentItem?, animated: Bool) {
        let previous = self.state
        self.story = story
        if previous != state {
            if let view = self.current {
                performSubviewRemoval(view, animated: animated, scale: true)
                self.current = nil
            }
            let current: ImageButton = ImageButton()
            
            current.autohighlight = false
            current.animates = false
            switch state {
            case .text:
                current.set(image: send_image, for: .Normal)
                current.set(image: send_image_active, for: .Highlight)
            case let .empty(isVoice: isVoice):
                current.set(image: isVoice ? voice_image : video_message_image, for: .Normal)
                current.set(image: isVoice ? voice_image_active : video_message_image_active, for: .Highlight)
            case .share:
                current.set(image: share_image, for: .Normal)
                current.set(image: share_image_active, for: .Highlight)
            }
            self.current = current
            current.frame = frame.size.bounds
            addSubview(current)
            if animated {
                current.layer?.animateAlpha(from: 0, to: 1, duration: 0.2)
                current.layer?.animateScaleSpring(from: 0.1, to: 1, duration: 0.2, bounce: false)
            }
        }
        
        self.state = state

        guard let current = self.current else {
            return
        }
        current.removeAllHandlers()
        
        if state == .share, story?.storyItem.isForwardingDisabled == true {
            if story?.canCopyLink == false {
                tooltip(for: current, text: strings().storyInputCantShare)
            } else {
                current.contextMenu = {
                    let menu = ContextMenu()
                    menu.addItem(ContextMenuItem(strings().modalCopyLink, handler: { [weak arguments, weak story] in
                        if let story = story {
                            arguments?.copyLink(story)
                        }
                    }, itemImage: MenuAnimation.menu_copy_link.value))
                    return menu
                }
            }
            
        } else {
            current.contextMenu = nil
            
            current.set(handler: { [weak arguments, weak self] _ in
                if state == .text {
                    if let story = self?.story, let peerId = story.peerId {
                        arguments?.sendMessage(peerId, story.storyItem.id)
                    }
                } else if state == .share {
                    if let story = self?.story {
                        arguments?.share(story)
                    }
                } else {
                    arguments?.toggleRecordType()
                }
            }, for: .Click)
            
            if case .empty = state {
                current.set(handler: { [weak arguments] _ in
                    if state == .text {
                    } else {
                        arguments?.startRecording(false)
                    }
                }, for: .LongMouseDown)
            }
        }
    }
}

final class StoryInputView : Control, TGModernGrowingDelegate, StoryInput {
    
    private let rtfAttachmentsDisposable = MetaDisposable()
    private var recordingView: StoryRecordingView?
    private var story: StoryContentItem?

    func updateInputText(_ state: ChatTextInputState, prevState: ChatTextInputState, animated: Bool) {
        if textView.string() != state.inputText || state.attributes != prevState.attributes {
            let range = NSMakeRange(state.selectionRange.lowerBound, state.selectionRange.upperBound - state.selectionRange.lowerBound)

            let current = textView.attributedString().copy() as! NSAttributedString
            let currentRange = textView.selectedRange()
            
            let item = SimpleUndoItem(attributedString: current, be: state.attributedString(storyTheme), wasRange: currentRange, be: range)
            self.textView.addSimpleItem(item)
        }

        if prevState.inputText.isEmpty {
            self.textView.scrollToCursor()
        }

    }
    
    func updateState(_ state: StoryInteraction.State, animated: Bool) {
        guard let arguments = self.arguments else {
            return
        }
        self.action.update(state: !isFirstResponder && self.story?.sharable == true ? .share : textView.string().isEmpty ? .empty(isVoice: state.recordType == .voice) : .text, arguments: arguments, story: self.story, animated: animated)
        
        self.updateInputState(animated: animated)
        self.updateRecoringState(state, animated: animated)
        
        if let story = self.story {
            self.likeAction.update(story, state: state, context: arguments.context, animated: animated)
        }
   
        self.updatePlaceholder()
    }
    
    private let stealthDisposable = MetaDisposable()
    private func updatePlaceholder() {
        guard let arguments = self.arguments else {
            return
        }
        let text: String
        if let cooldown = arguments.interaction.presentation.stealthMode.activeUntilTimestamp {
            stealthDisposable.set(delaySignal(0.3).start(completed: { [weak self] in
                self?.updatePlaceholder()
            }))
            
            let timer = smartTimeleftText(Int(cooldown - arguments.context.timestamp))
            text = strings().storyStealthModePlaceholder(timer)
        } else {
            stealthDisposable.set(nil)
            text = strings().storyInputPlaceholder
        }
        textView.setPlaceholderAttributedString(.initialize(string: text, color: placeholderColor, font: .normal(.text)), update: true)
    }
    
    private func updateRecoringState(_ state: StoryInteraction.State, animated: Bool) {
        guard let arguments = self.arguments else {
            return
        }
        if let recording = state.inputRecording {
            let current: StoryRecordingView
            if let view = self.recordingView {
                current = view
            } else {
                current = StoryRecordingView(frame: NSMakeRect(0, 0, frame.width, frame.height), arguments: arguments, state: state, recorder: recording)
                self.recordingView = current
                self.addSubview(current)
                
                if animated {
                    current.layer?.animateAlpha(from: 0, to: 1, duration: 0.2)
                }
            }
            current.updateState(state)
        } else if let view = self.recordingView {
            performSubviewRemoval(view, animated: animated)
            self.recordingView = nil
        }
    }
    
    func update(_ story: StoryContentItem, animated: Bool) {
        self.story = story
        guard let arguments = self.arguments else {
            return
        }
        self.likeAction.update(story, state: arguments.interaction.presentation, context: arguments.context, animated: animated)
    }
    
    func textViewHeightChanged(_ height: CGFloat, animated: Bool) {
        let size = NSMakeSize(frame.width, height + 16)
        self.updateInputSize(size: size, animated: animated)
    }
    
    private func updateInputSize(size: NSSize, animated: Bool) {
        let transition: ContainedViewLayoutTransition
        if animated {
            transition = .animated(duration: 0.2, curve: .easeOut)
        } else {
            transition = .immediate
        }
        guard let window = self.window else {
            return
        }
                
        let wSize = NSMakeSize(window.contentView!.frame.width - 100, window.contentView!.frame.height - 110)
        let aspect = StoryView.size.aspectFitted(wSize)
        
        var size = size
        if self.inputState == .focus, let inputContextSize = self.inputContextSize {
            size.height += inputContextSize.height
        }

        transition.updateFrame(view: self, frame: CGRect(origin: CGPoint(x: 0, y: aspect.height + 10 - size.height + 50), size: size))
        self.updateLayout(size: size, transition: transition)

    }
    
    func textViewEnterPressed(_ event: NSEvent) -> Bool {
        if FastSettings.checkSendingAbility(for: event) {
            let text = textView.string().trimmed
            if !text.isEmpty {
                if let story = self.story, let peerId = story.peerId {
                    self.arguments?.sendMessage(peerId, story.storyItem.id)
                }
            }
            return true
        }
        return false

    }
    
    func textViewTextDidChange(_ string: String) {        
        let attributed = self.textView.attributedString()
        let range = self.textView.selectedRange()
        let state = ChatTextInputState(inputText: attributed.string, selectionRange: range.location ..< range.location + range.length, attributes: chatTextAttributes(from: attributed))
        if let groupId = self.groupId {
            arguments?.interaction.update({ current in
                var current = current
                current.inputs[groupId] = state
                return current
            })
        }
        self.updateInputState()
    }
    
    func textViewTextDidChangeSelectedRange(_ range: NSRange) {
        let attributed = self.textView.attributedString()
        let attrs = chatTextAttributes(from: attributed)
        let state = ChatTextInputState(inputText: attributed.string, selectionRange: range.min ..< range.max, attributes: attrs)
        if let groupId = self.groupId {
            arguments?.interaction.update({ current in
                var current = current
                current.inputs[groupId] = state
                return current
            })
        }
        self.updateInputState()
    }
    
    func makeUrl() {
        self.makeUrl(of: textView.selectedRange())
    }
    
    func makeUrl(of range: NSRange) {
        guard range.min != range.max, let window = kitWindow else {
            return
        }
        var effectiveRange:NSRange = NSMakeRange(NSNotFound, 0)
        let defaultTag: TGInputTextTag? = self.textView.attributedString().attribute(NSAttributedString.Key(rawValue: TGCustomLinkAttributeName), at: range.location, effectiveRange: &effectiveRange) as? TGInputTextTag
        
        
        let defaultUrl = defaultTag?.attachment as? String
        
        if effectiveRange.location == NSNotFound || defaultTag == nil {
            effectiveRange = range
        }
        
        showModal(with: InputURLFormatterModalController(string: self.textView.string().nsstring.substring(with: effectiveRange), defaultUrl: defaultUrl, completion: { [weak self] text, url in
            self?.textView.addLink(url, text: text, range: effectiveRange)
        }, presentation: storyTheme), for: window)
        
    }
    
    func textViewDidPaste(_ pasteboard: NSPasteboard) -> Bool {
        if let window = kitWindow, let arguments = self.arguments {
            
            let context = arguments.context
            let chatInteraction = arguments.chatInteraction
            
            let result = InputPasteboardParser.proccess(pasteboard: pasteboard, chatInteraction: chatInteraction, window: window)
            if result {
                if let data = pasteboard.data(forType: .kInApp) {
                    let decoder = AdaptedPostboxDecoder()
                    if let decoded = try? decoder.decode(ChatTextInputState.self, from: data) {
                        let attributed = decoded.unique(isPremium: context.isPremium).attributedString(storyTheme)
                        let current = textView.attributedString().copy() as! NSAttributedString
                        let currentRange = textView.selectedRange()
                        let (attributedString, range) = current.appendAttributedString(attributed, selectedRange: currentRange)
                        let item = SimpleUndoItem(attributedString: current, be: attributedString, wasRange: currentRange, be: range)
                        self.textView.addSimpleItem(item)
                        DispatchQueue.main.async { [weak self] in
                            self?.textView.scrollToCursor()
                        }
                        
                        return true
                    }
                } else if let data = pasteboard.data(forType: .rtf) {
                    if let attributed = (try? NSAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil)) ?? (try? NSAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil))  {
                        
                        let (attributed, attachments) = attributed.applyRtf()
                        
                        if !attachments.isEmpty {
                            rtfAttachmentsDisposable.set((prepareTextAttachments(attachments) |> deliverOnMainQueue).start(next: { urls in
                                if !urls.isEmpty {
                                    chatInteraction.showPreviewSender(urls, true, attributed)
                                }
                            }))
                        } else {
                            let current = textView.attributedString().copy() as! NSAttributedString
                            let currentRange = textView.selectedRange()
                            let (attributedString, range) = current.appendAttributedString(attributed, selectedRange: currentRange)
                            let item = SimpleUndoItem(attributedString: current, be: attributedString, wasRange: currentRange, be: range)
                            self.textView.addSimpleItem(item)
                        }
                        DispatchQueue.main.async { [weak self] in
                            self?.textView.scrollToCursor()
                        }
                        return true
                    }
                }
            }
            return !result
        }
        return false
    }
    
    func maxCharactersLimit(_ textView: TGModernGrowingTextView!) -> Int32 {
        return 255
    }
    
    func textViewSize(_ textView: TGModernGrowingTextView!) -> NSSize {
        return NSMakeSize(frame.width - 100, textView.frame.height)
    }
    
    func textViewIsTypingEnabled() -> Bool {
        return self.arguments?.interaction.presentation.inputRecording == nil
    }
    
    func responderDidUpdate() {
        
        self.inputState = self.isFirstResponder ? .focus : .none
        self.updateInputState()
       // self.textView.update(true)
        DispatchQueue.main.async {
            self.textView.setSelectedRange(NSMakeRange(self.textView.string().length, 0))
        }
    }
    
    func canTransformInputText() -> Bool {
        return true
    }
    
    
    
    func updateInputState(animated: Bool = true) {
        
        guard let window = self.window, let arguments = self.arguments else {
            return
        }
        
        let wWdith = window.contentView!.frame.width
        
        let maxSize = NSMakeSize(wWdith - 100, window.contentView!.frame.height - 110)
        let supersize = StoryView.size.aspectFitted(maxSize)
        let size: NSSize
        if arguments.interaction.presentation.inputRecording != nil {
            size = NSMakeSize(min(supersize.width + 60, wWdith - 20), self.textViewSize(self.textView).height + 16)
            textView.inputView.textContainer?.maximumNumberOfLines = 0
            textView.inputView.textContainer?.lineBreakMode = .byWordWrapping
            textView.inputView.isSelectable = true
            textView.inputView.isEditable = !arguments.interaction.presentation.inTransition
        } else {
            switch self.inputState {
            case .focus:
                size = NSMakeSize(min(supersize.width + 60, wWdith - 20), self.textViewSize(self.textView).height + 16)
                textView.inputView.textContainer?.maximumNumberOfLines = 0
                textView.inputView.textContainer?.lineBreakMode = .byWordWrapping
                textView.inputView.isSelectable = true
                textView.inputView.isEditable = !arguments.interaction.presentation.inTransition
            case .none:
                size = NSMakeSize(supersize.width, self.textViewSize(self.textView).height + 16)
                textView.inputView.textContainer?.maximumNumberOfLines = 1
                textView.inputView.textContainer?.lineBreakMode = .byTruncatingTail
                textView.inputView.isSelectable = false
                textView.inputView.isEditable = !arguments.interaction.presentation.inTransition
            }
        }
        
        
        self.action.update(state: !isFirstResponder && self.story?.sharable == true ? .share : textView.string().isEmpty ? .empty(isVoice: arguments.interaction.presentation.recordType == .voice) : .text, arguments: arguments, story: self.story, animated: animated)
        self.updateInputSize(size: size, animated: animated)
        
    }
    
    

    
    private(set) var inputState: StoryInputState = .none {
        didSet {
            if oldValue != inputState {
                inputStateDidUpdate?(inputState)
            }
        }
    }
    
    private var inputStateDidUpdate:((StoryInputState)->Void)? = nil
    
    func installInputStateUpdate(_ f: ((StoryInputState)->Void)?) {
        self.inputStateDidUpdate = f
    }
    
    func like(_ like: StoryReactionAction, resetIfNeeded: Bool) {
        guard let arguments = self.arguments, let story = self.story else {
            return
        }
        let state = arguments.interaction.presentation
        if story.storyItem.myReaction == like.item.reaction || (resetIfNeeded && story.storyItem.myReaction != nil) {
            self.arguments?.like(nil, state)
        } else {
            
            self.arguments?.like(like.item.reaction, state)
            self.likeAction.react(like, state: state, context: arguments.context)
        }
    }
    
    
    let textView = TGModernGrowingTextView(frame: NSMakeRect(0, 0, 100, 34))
    private let textContainer = View()
    private let inputContextContainer = View()
    private let inputContext_Relative = View()
    private let visualEffect: VisualEffect
    private let attach = ImageButton()
    private let action = StoryReplyActionButton(frame: NSMakeRect(0, 0, 50, 50))
    private let likeAction = StoryLikeActionButton(frame: NSMakeRect(0, 0, 50, 50))
    
    var actionControl: NSView {
        return action
    }
    
    
    
    required init(frame frameRect: NSRect) {
        self.visualEffect = VisualEffect()
        super.init(frame: frameRect)
        self.background = .blackTransparent
      //  addSubview(visualEffect)
        addSubview(attach)
        addSubview(action)
        addSubview(likeAction)
        addSubview(textContainer)
        addSubview(inputContextContainer)
        
        self.layer?.masksToBounds = false
        
        inputContextContainer.addSubview(inputContext_Relative)
        
        textContainer.addSubview(textView)
        
        self.set(handler: { [weak self] _ in
            self?.window?.makeFirstResponder(self?.input)
        }, for: .Click)
        
//        stickers.animates = false
//        attach.animates = false
//        action.animates = false
        
                
        
        textView.textFont = .normal(.text)
        textView.textColor = .white
        textView.delegate = self
        textView.inputView.appearance = storyTheme.appearance
                
       // self.background = .random
        
        visualEffect.bgColor = .blackTransparent
      //  textView.background = .random
        
        attach.set(image: attach_image, for: .Normal)
        attach.set(image: attach_image_active, for: .Highlight)
        attach.sizeToFit(.zero, NSMakeSize(50, 50), thatFit: true)
        
        textView.installGetAttach({ [weak self] attachment, size in
            guard let context = self?.arguments?.context else {
                return nil
            }
            
            let rect = size.bounds.insetBy(dx: -1.5, dy: -1.5)
            let view = ChatInputAnimatedEmojiAttach(frame: rect)
            view.set(attachment, size: rect.size, context: context)
            return view
        })
        
        attach.contextMenu = { [weak self] in
            
            let menu = ContextMenu(presentation: AppMenu.Presentation.current(storyTheme.colors), betterInside: true)
            var items: [ContextMenuItem] = []
            
            
            
            items.append(ContextMenuItem(strings().storyInputAttach, handler: { [weak self] in
                self?.arguments?.attachPhotoOrVideo(nil)
            }, itemImage: MenuAnimation.menu_shared_media.value))
            
            items.append(ContextMenuItem(strings().storyInputFile, handler: { [weak self] in
                self?.arguments?.attachFile()
            }, itemImage: MenuAnimation.menu_file.value))
            
            for item in items {
                menu.addItem(item)
            }
            return menu
        }
                
        likeAction.set(handler: { [weak self] control in
            
            let control = control as! StoryLikeActionButton
            
            guard let arguments = self?.arguments else {
                return
            }
            let state = arguments.interaction.presentation
            if state.inputInFocus {
                self?.arguments?.showEmojiPanel(control)
            } else {
                self?.like(.init(item: .builtin("❤️".withoutColorizer), fromRect: nil), resetIfNeeded: true)
            }
        }, for: .Click)
        
        
        
        likeAction.set(handler: { [weak self] control in
            guard let arguments = self?.arguments, let story = self?.story else {
                return
            }
            arguments.showLikePanel(control, story)
        }, for: .RightDown)
        
        self.layer?.cornerRadius = 10
      //  self.action.update(state: .empty(isVoice: FastSettings.recordingState == .voice), animated: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isFirstResponder: Bool {
        return window?.firstResponder == textView.inputView
    }
    
    var input: NSTextView? {
        return self.textView.inputView
    }
    var text: TGModernGrowingTextView? {
        return self.textView
    }
    
    var inputReactionsControl: Control? {
        return self.likeAction
    }
    
    func resetInputView() {
        window?.makeFirstResponder(nil)
    }

    
    private var arguments:StoryArguments? = nil
    private var groupId: PeerId? = nil
    
    func setArguments(_ arguments: StoryArguments?, groupId: PeerId?) -> Void {
        self.arguments = arguments
        self.groupId = groupId
        
        self.updateInputState()
        
        let attributedString = arguments?.interaction.presentation.findInput(groupId).attributedString(storyTheme)
        if let attributedString = attributedString, !attributedString.string.isEmpty {
            self.textView.setAttributedString(attributedString, animated: false)
        }
        if let arguments = arguments {
            self.updateState(arguments.interaction.presentation, animated: false)
        }
    }
    
    private var inputContextSize: NSSize? = nil
    
    func updateInputContext(with result:ChatPresentationInputQueryResult?, context: InputContextHelper, animated:Bool) {
        context.updatedSize = { [weak self] size, animated in
            self?.inputContextSize = size
            self?.updateInputState(animated: animated)
        }
        context.getHeight = {
            return 150
        }
        context.getPresentation = {
            storyTheme
        }
        context.getBackground = {
            .clear
        }
        context.onDisappear = { [weak self] in
            self?.inputContextSize = nil
            self?.updateInputState(animated: animated)
        }
        context.context(with: result, for: inputContextContainer, relativeView: inputContext_Relative, position: .above, animated: animated)
    }
    
    
    deinit {
        rtfAttachmentsDisposable.dispose()
        stealthDisposable.dispose()
    }
    
    func updateLayout(size: NSSize, transition: ContainedViewLayoutTransition) {
        guard let window = self.window else {
            return
        }
        transition.updateFrame(view: action, frame: NSMakeRect(size.width - action.frame.width, size.height - action.frame.height, action.frame.width, action.frame.height))
        transition.updateFrame(view: likeAction, frame: NSMakeRect(action.frame.minX - likeAction.frame.width, size.height - action.frame.height, likeAction.frame.width, likeAction.frame.height))
                
        
        transition.updateFrame(view: attach, frame: NSMakeRect(0, size.height - attach.frame.height, attach.frame.width, attach.frame.height))
        transition.updateFrame(view: visualEffect, frame: focus(window.frame.size))
        
        
        var textRect = NSMakeSize(size.width - 150, textView.frame.height + 16).bounds
        textRect.origin.x = 50
        textRect.origin.y = size.height - textRect.height
        
        transition.updateFrame(view: textContainer, frame: textRect)

        if let inputContextSize = self.inputContextSize {
            transition.updateFrame(view: inputContextContainer, frame: CGRect(origin: CGPoint.init(x: 0, y: textRect.minY - inputContextSize.height), size: NSMakeSize(size.width, inputContextSize.height)))
        } else {
            transition.updateFrame(view: inputContextContainer, frame: CGRect(origin: CGPoint(x: 0, y: textRect.minY - 1), size: NSMakeSize(size.width, 1)))
        }
        
        transition.updateFrame(view: inputContext_Relative, frame: CGRect(origin: CGPoint(x: 0, y: inputContextContainer.frame.height), size: NSMakeSize(size.width, 1)))
        
        transition.updateFrame(view: textView, frame: textContainer.bounds.insetBy(dx: 0, dy: 8))
    }
    
    override func layout() {
        super.layout()
        self.updateLayout(size: self.frame.size, transition: .immediate)
    }
}