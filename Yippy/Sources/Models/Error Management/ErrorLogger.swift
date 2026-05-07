//
//  ErrorLogger.swift
//  Yippy
//
//  Created by Matthew Davidson on 17/10/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation

class ErrorLogger: Logger, @unchecked Sendable {
    
    static let general = ErrorLogger(url: Constants.urls.errorLog)
}

