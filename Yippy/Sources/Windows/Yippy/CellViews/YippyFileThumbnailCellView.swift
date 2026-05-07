//
//  YippyFileThumbnailCellView.swift
//  Yippy
//
//  Created by Matthew Davidson on 11/10/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa
import QuickLookThumbnailing

class YippyFileThumbnailCellView: YippyItemBaseCellView, YippyItem {
    
    override class var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(Accessibility.identifiers.yippyFileThumbnailCellView)
    }
    
    static let fileNamePadding = NSEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
    
    static let imageSize = NSSize(width: 300, height: 200)
    
    static let imageTopPadding: CGFloat = 5
    
    var previewView: NSImageView!
    
    private var representedFileURL: URL?

    override func commonInit() {
        super.commonInit()
        
        previewView = NSImageView(frame: .zero)
        contentView.addSubview(previewView)
        
        setupPreviewView()
        setupItemTextView()
    }
    
    func setupPreviewView() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.imageAlignment = .alignCenter
        previewView.imageScaling = .scaleProportionallyUpOrDown
        contentView.addConstraint(NSLayoutConstraint(item: previewView!, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: Self.imageTopPadding))
        previewView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        previewView.widthAnchor.constraint(equalToConstant: Self.imageSize.width).isActive = true
        previewView.heightAnchor.constraint(equalToConstant: Self.imageSize.height).isActive = true
    }
    
    func setupItemTextView() {
        itemTextView.translatesAutoresizingMaskIntoConstraints = false
        itemTextView.alignment = .center
        itemTextView.textContainer?.lineFragmentPadding = 0
        itemTextView.textContainerInset = .zero
        contentView.addConstraint(NSLayoutConstraint(item: itemTextView!, attribute: .top, relatedBy: .equal, toItem: previewView, attribute: .bottom, multiplier: 1, constant: Self.fileNamePadding.top))
        contentView.addConstraint(NSLayoutConstraint(item: itemTextView!, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: Self.fileNamePadding.left))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .trailing, relatedBy: .equal, toItem: itemTextView, attribute: .trailing, multiplier: 1, constant: Self.fileNamePadding.right))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .bottom, relatedBy: .equal, toItem: itemTextView, attribute: .bottom, multiplier: 1, constant: Self.fileNamePadding.bottom))
    }
    
    func setupCell(withYippyTableView yippyTableView: YippyTableView, forHistoryItem historyItem: HistoryItem, at i: Int) {
        guard let url = historyItem.getFileUrl() else { return }
        representedFileURL = url
        previewView.image = NSWorkspace.shared.icon(forFile: url.path)
        itemTextView.attributedText = formatFileUrl(url)
        setupShortcutTextView(at: i)
        setHighlight(isSelected: yippyTableView.isRowSelected(i))
        
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        let request = QLThumbnailGenerator.Request(fileAt: url, size: Self.imageSize, scale: scale, representationTypes: .thumbnail)
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] thumbnail, error in
            let thumbnailData = thumbnail?.nsImage.tiffRepresentation
            let errorDescription = error?.localizedDescription
            
            DispatchQueue.main.async {
                guard let self = self, self.representedFileURL == url else {
                    return
                }

                if let thumbnailData = thumbnailData {
                    self.previewView.image = NSImage(data: thumbnailData)
                }
                else if let errorDescription = errorDescription {
                    ErrorLogger.general.log(YippyError(localizedDescription: "Failed to create thumbnail for file with url '\(url.path)' due to error: \(errorDescription)"))
                }
            }
        }
    }
    
    static func getItemHeight(withYippyTableView yippyTableView: YippyTableView, forHistoryItem historyItem: HistoryItem) -> CGFloat {
        // Calculate the width of the cell
        let cellWidth = floor(yippyTableView.cellWidth)
        
        // Calculate the text container width
        let textContainerWidth = cellWidth - contentViewInsets.xTotal - fileNamePadding.xTotal
        
        // Create the attributed string
        let str = formatFileUrl(historyItem.getFileUrl()!)
        
        // Calculate the height of the text
        let estHeight = str.calculateSize(withMaxWidth: textContainerWidth).height
        
        // Calculate the height of the cell
        let height = estHeight + contentViewInsets.yTotal + fileNamePadding.yTotal + imageSize.height + imageTopPadding
        
        return ceil(height)
    }
    
    static func makeItem() -> YippyItem {
        return YippyFileThumbnailCellView(frame: .zero)
    }
}
