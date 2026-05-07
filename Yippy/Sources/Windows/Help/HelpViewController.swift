//
//  HelpViewController.swift
//  Yippy
//
//  Created by Matthew Davidson on 11/9/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa

class HelpViewController: NSViewController {
    
    private static let waitingContentSize = NSSize(width: 457, height: 253)
    private static let instructionsContentSize = NSSize(width: 568, height: 468)

    private var timer: Timer?
    
    @IBOutlet var waitingView: NSView!
    @IBOutlet var instructionsView: NSView!
    
    private var hasControl = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControlState(forceUpdate: true)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        startTimer()
        refreshControlState(forceUpdate: true)
        updateSize()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        stopTimer()
    }

    private func startTimer() {
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(controlTimerFired(_:)), userInfo: nil, repeats: true)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func controlTimerFired(_ timer: Timer) {
        refreshControlState()
    }

    private func refreshControlState(forceUpdate: Bool = false) {
        let newValue = Helper.isControlGranted()
        guard forceUpdate || newValue != hasControl else { return }

        hasControl = newValue
        waitingView.isHidden = hasControl
        instructionsView.isHidden = !hasControl
        updateSize()
    }
    
    private func updateSize() {
        let contentSize = hasControl ? Self.instructionsContentSize : Self.waitingContentSize
        self.view.window?.setContentSize(contentSize)
        self.view.window?.center()
    }
}
