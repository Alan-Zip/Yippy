//
//  HistoryItem+YippyItem.swift
//  Yippy
//
//  Created by Matthew Davidson on 14/10/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

extension HistoryItem {
    
    func getTableViewItemType() -> YippyItem.Type {
        if let fileUrl = getFileUrl() {
            if fileUrl.yippyUsesThumbnailCell {
                return YippyFileThumbnailCellView.self
            }
            else {
                return YippyFileIconCellView.self
            }
        }
        else if getColor() != nil {
            return YippyColorCellView.self
        }
        else if types.contains(.tiff) || types.contains(.png) {
            return YippyTiffCellView.self
        }
        else {
            return YippyTextCellView.self
        }
    }
}

private extension URL {
    var yippyUsesThumbnailCell: Bool {
        guard let contentType = try? resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }

        return contentType.conforms(to: .image)
            || contentType.conforms(to: .pdf)
            || contentType.conforms(to: .movie)
    }
}
