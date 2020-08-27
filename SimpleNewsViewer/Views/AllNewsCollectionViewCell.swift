//
//  AllNewsCollectionViewCell.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 27/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import UIKit

class AllNewsCollectionViewCell: UICollectionViewCell {
    //MARK: - Properties
    @IBOutlet private weak var lastNewsLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var unreadCounterLabel: UILabel!
    
    //MARK: - Setters
    func set(lastNews: String?, unreadCounter: Int) {
        titleLabel.text = NSLocalizedString("All News", comment: "")
        lastNewsLabel.text = lastNews
        let formatString = NSLocalizedString("unread counter", comment: "")
        unreadCounterLabel.text = String.localizedStringWithFormat(formatString, unreadCounter )
    }
}
