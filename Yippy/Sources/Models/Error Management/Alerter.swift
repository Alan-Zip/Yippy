//
//  Alerter.swift
//  Yippy
//
//  Created by Matthew Davidson on 20/10/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa

class Alerter: @unchecked Sendable {
    
    static let general = Alerter()
    
    func show(_ alertable: any Alertable) {
        Task { @MainActor in
            alertable.createAlert().runModal()
        }
    }
}
