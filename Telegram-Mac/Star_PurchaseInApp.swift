//
//  Star_PurchaseInApp.swift
//  Telegram
//
//  Created by Mikhail Filimonov on 10.05.2024.
//  Copyright © 2024 Telegram. All rights reserved.
//

import Foundation
import TGUIKit
import SwiftSignalKit
import TelegramCore
import Postbox


private final class HeaderItem : GeneralRowItem {
    fileprivate let context: AccountContext
    fileprivate let peer: EnginePeer
    fileprivate let request: State.Request
    fileprivate let myBalance: Int64
    fileprivate let close:()->Void
    
    
    fileprivate let balanceLayout: TextViewLayout
    fileprivate let headerLayout: TextViewLayout
    fileprivate let infoLayout: TextViewLayout

    

    init(_ initialSize: NSSize, stableId: AnyHashable, context: AccountContext, peer: EnginePeer, myBalance: Int64, request: State.Request, viewType: GeneralViewType, action:@escaping()->Void, close:@escaping()->Void) {
        self.context = context
        self.peer = peer
        self.myBalance = myBalance
        self.request = request
        self.close = close
        
        let balanceAttr = NSMutableAttributedString()
        balanceAttr.append(string: "Balance\n\(clown)\(myBalance)", color: theme.colors.text, font: .normal(.text))
        balanceAttr.insertEmbedded(.embeddedAnimated(LocalAnimatedSticker.star_currency.file, playPolicy: .onceEnd), for: clown)
        
        self.balanceLayout = .init(balanceAttr, alignment: .right)
        
        self.headerLayout = .init(.initialize(string: "Confirm Your Purchase", color: theme.colors.text, font: .medium(.title)), alignment: .center)
        
        let infoAttr = NSMutableAttributedString()
        infoAttr.append(string: "Do you want to buy **\"\(request.info)\"** in **\(peer._asPeer().displayTitle)** **for \(request.count) Stars**?", color: theme.colors.text, font: .normal(.text))
        infoAttr.detectBoldColorInString(with: .medium(.text))
        self.infoLayout = .init(infoAttr, alignment: .center)
        
        
        super.init(initialSize, stableId: stableId, viewType: viewType, action: action, inset: .init())
    }
    
    override func makeSize(_ width: CGFloat, oldWidth: CGFloat = 0) -> Bool {
        _ = super.makeSize(width, oldWidth: oldWidth)
        
        self.balanceLayout.measure(width: .greatestFiniteMagnitude)

        self.headerLayout.measure(width: width - 40)
        self.infoLayout.measure(width: width - 40)

        return true
    }
    
    override var height: CGFloat {
        return 10 + 80 + 10 + headerLayout.layoutSize.height + 10 + infoLayout.layoutSize.height + 10 + 40 + 10
    }
    
    override func viewClass() -> AnyClass {
        return HeaderItemView.self
    }
}

private final class AcceptView : Control {
    private let textView = InteractiveTextView()
    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(textView)
        layer?.cornerRadius = 10
        scaleOnClick = true
        self.set(background: theme.colors.accent, for: .Normal)
        
        textView.userInteractionEnabled = false
    }
    
    func update(_ item: HeaderItem, animated: Bool) {
        let attr = NSMutableAttributedString()
        
        attr.append(string: "Confirm and Pay \(clown)\(item.request.count)", color: .white, font: .medium(.text))
        attr.insertEmbedded(.embedded(name: "Icon_Peer_Premium", color: NSColor.white, resize: false), for: clown)
        
        let layout = TextViewLayout(attr)
        layout.measure(width: item.width - 60)
        
        textView.set(text: layout, context: item.context)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        super.layout()
        textView.center()
    }
}

private final class HeaderItemView : GeneralContainableRowView {
    
    private let dismiss = ImageButton()
    private let balance = InteractiveTextView()
    private var photo: TransformImageView?
    private var avatar: AvatarControl?
    private let header = InteractiveTextView()
    private let info = InteractiveTextView()
    private let sceneView: GoldenStarSceneView
    
    private let accept: AcceptView = AcceptView(frame: .zero)
    
    required init(frame frameRect: NSRect) {
        self.sceneView = GoldenStarSceneView(frame: NSMakeRect(0, 0, frameRect.width, 150))
        super.init(frame: frameRect)
        addSubview(sceneView)
        addSubview(dismiss)
        addSubview(balance)
        addSubview(header)
        addSubview(info)
        
        addSubview(accept)
        
        sceneView.hideStar()
        
        
        dismiss.set(handler: { [weak self] _ in
            if let item = self?.item as? HeaderItem {
                item.close()
            }
        }, for: .Click)
        
        accept.set(handler: { [weak self] _ in
            if let item = self?.item as? HeaderItem {
                item.action()
            }
        }, for: .Click)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func set(item: TableRowItem, animated: Bool = false) {
        super.set(item: item, animated: animated)
        
        guard let item = item as? HeaderItem else {
            return
        }
        
//        self.imageView?.setFrameSize(item.imageSize)

        
        if let photo = item.request.invoice.photo {
            if let view = self.avatar {
                performSubviewRemoval(view, animated: animated)
                self.avatar = nil
            }
            let current: TransformImageView
            if let view = self.photo {
                current = view
            } else {
                current = TransformImageView(frame: NSMakeRect(0, 0, 80, 80))
                current.layer?.cornerRadius = current.frame.height / 2
                addSubview(current)
                self.photo = current
            }
            
            current.setSignal(chatMessageWebFilePhoto(account: item.context.account, photo: photo, scale: backingScaleFactor))
    
            _ = fetchedMediaResource(mediaBox: item.context.account.postbox.mediaBox, userLocation: .other, userContentType: .other, reference: MediaResourceReference.standalone(resource: photo.resource)).start()
    
            current.set(arguments: TransformImageArguments(corners: .init(radius: .cornerRadius), imageSize: photo.dimensions?.size ?? NSMakeSize(80, 80), boundingSize: current.frame.size, intrinsicInsets: .init()))

            
        } else {
            if let view = self.photo {
                performSubviewRemoval(view, animated: animated)
                self.photo = nil
            }
            
            let current: AvatarControl
            if let view = self.avatar {
                current = view
            } else {
                current = AvatarControl(font: .avatar(14))
                current.setFrameSize(NSMakeSize(80, 80))
                self.avatar = current
                addSubview(current)
            }
            current.setPeer(account: item.context.account, peer: item.peer._asPeer())
        }
        
        
        dismiss.set(image: theme.icons.modalClose, for: .Normal)
        dismiss.sizeToFit()
        dismiss.scaleOnClick = true
        dismiss.autohighlight = false
        
        balance.set(text: item.balanceLayout, context: item.context)
        header.set(text: item.headerLayout, context: item.context)
        info.set(text: item.infoLayout, context: item.context)
        
        accept.update(item, animated: animated)
        accept.setFrameSize(NSMakeSize(frame.width - 40, 40))
        
        needsLayout = true

    }
    
    override var backdorColor: NSColor {
        return theme.colors.background
    }
    
    override func layout() {
        super.layout()
        dismiss.setFrameOrigin(NSMakePoint(10, floorToScreenPixels((50 - dismiss.frame.height) / 2) - 10))
        if let photo {
            photo.centerX(y: 10)
        }
        if let avatar {
            avatar.centerX(y: 10)
        }
        sceneView.centerX(y: -10)
        balance.setFrameOrigin(NSMakePoint(frame.width - 12 - balance.frame.width, floorToScreenPixels((50 - balance.frame.height) / 2) - 10))
        
        let headerY = photo?.frame.maxY ?? avatar?.frame.maxY ?? 0
        
        header.centerX(y: headerY + 10)
        info.centerX(y: header.frame.maxY + 10)
        accept.centerX(y: frame.height - accept.frame.height)
    }
}

private final class Arguments {
    let context: AccountContext
    let dismiss: ()->Void
    let buy: ()->Void
    init(context: AccountContext, dismiss: @escaping()->Void, buy: @escaping()->Void) {
        self.context = context
        self.dismiss = dismiss
        self.buy = buy
    }
}

private struct State : Equatable {
    struct Request : Equatable {
        let count: Int64
        let info: String
        let invoice: TelegramMediaInvoice
    }
    var request: Request
    var peer: EnginePeer?
    var myBalance: Int64?
    var starsState: StarsContext.State?
    
    var form: BotPaymentForm?
}

private let _id_header = InputDataIdentifier("_id_header")

private func entries(_ state: State, arguments: Arguments) -> [InputDataEntry] {
    var entries:[InputDataEntry] = []
    
    var sectionId:Int32 = 0
    var index: Int32 = 0
    
    entries.append(.custom(sectionId: sectionId, index: index, value: .none, identifier: .init("h1"), equatable: nil, comparable: nil, item: { initialSize, stableId in
        return GeneralRowItem(initialSize, height: 10, stableId: stableId, backgroundColor: theme.colors.background)
    }))
    sectionId += 1
    
    if let peer = state.peer, let myBalance = state.myBalance {
        entries.append(.custom(sectionId: sectionId, index: index, value: .none, identifier: _id_header, equatable: .init(state), comparable: nil, item: { initialSize, stableId in
            return HeaderItem(initialSize, stableId: stableId, context: arguments.context, peer: peer, myBalance: myBalance, request: state.request, viewType: .legacy, action: arguments.buy, close: arguments.dismiss)
        }))
    } else {
        entries.append(.custom(sectionId: sectionId, index: index, value: .none, identifier: .init("loading"), equatable: nil, comparable: nil, item: { initialSize, stableId in
            return LoadingTableItem(initialSize, height: 219, stableId: stableId, backgroundColor: theme.colors.background)
        }))
    }
    
    entries.append(.custom(sectionId: sectionId, index: index, value: .none, identifier: .init("h2"), equatable: nil, comparable: nil, item: { initialSize, stableId in
        return GeneralRowItem(initialSize, height: 20, stableId: stableId, backgroundColor: theme.colors.background)
    }))
    sectionId += 1
    
    return entries
}

func Star_PurschaseInApp(context: AccountContext, invoice: TelegramMediaInvoice, source: BotPaymentInvoiceSource) -> InputDataModalController {

    let actionsDisposable = DisposableSet()

    let initialState = State(request: .init(count: invoice.totalAmount, info: invoice.title, invoice: invoice), myBalance: nil)
    
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((State) -> State) -> Void = { f in
        statePromise.set(stateValue.modify (f))
    }
    
    let starsContext = context.starsContext
    
    let formAndMaybeValidatedInfo = context.engine.payments.fetchBotPaymentForm(source: source, themeParams: nil)
    
    actionsDisposable.add(formAndMaybeValidatedInfo.startStrict(next: { [weak actionsDisposable] form in
        updateState { current in
            var current = current
            current.form = form
            return current
        }
        
        actionsDisposable?.add(combineLatest(context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(id: form.paymentBotId)), starsContext.state).startStrict(next: { peer, starsState in
            updateState { current in
                var current = current
                current.peer = peer
                current.myBalance = starsState?.balance
                current.starsState = starsState
                return current
            }
        }))
        
    }))
    
    
    
    var close:(()->Void)? = nil

    let arguments = Arguments(context: context, dismiss: {
        close?()
    }, buy: {
        let state = stateValue.with { $0 }
        let myBalance = state.myBalance ?? 0
        if let peer = state.peer {
            if state.request.count > myBalance {
                showModal(with: Star_ListScreen(context: context, source: .purchase(peer, state.request.count)), for: context.window)
            } else {
                if let form = state.form {
                    _ = showModalProgress(signal: context.engine.payments.sendStarsPaymentForm(formId: form.id, source: source), for: context.window).startStandalone(next: { result in
                        switch result {
                        case let .done(receiptMessageId):
                            starsContext.add(balance: -state.request.count)
                            showModalText(for: context.window, text: "You acquired \"\(state.request.info)\" in \(peer._asPeer().displayTitle) for \(state.request.count) Stars.")
                            PlayConfetti(for: context.window, stars: true)
                            close?()
                        default:
                            break
                        }
                    }, error: { error in
                        let text: String
                        switch error {
                        case .alreadyPaid:
                            text = strings().checkoutErrorInvoiceAlreadyPaid
                        case .generic:
                            text = strings().unknownError
                        case .paymentFailed:
                            text = strings().checkoutErrorPaymentFailed
                        case .precheckoutFailed:
                            text = strings().checkoutErrorPrecheckoutFailed
                        }
                        showModalText(for: context.window, text: text)
                    })
                }
            }
        }
    })
    
    let signal = statePromise.get() |> deliverOnPrepareQueue |> map { state in
        return InputDataSignalValue(entries: entries(state, arguments: arguments))
    }
    
    let controller = InputDataController(dataSignal: signal, title: "")
    
    controller.onDeinit = {
        actionsDisposable.dispose()
    }
    
    controller.contextObject = starsContext

  
    
    let modalController = InputDataModalController(controller, modalInteractions: nil)
    
    controller.leftModalHeader = ModalHeaderData(image: theme.icons.modalClose, handler: { [weak modalController] in
        modalController?.close()
    })
    
    close = { [weak modalController] in
        modalController?.modal?.close()
    }
    
    return modalController
}



