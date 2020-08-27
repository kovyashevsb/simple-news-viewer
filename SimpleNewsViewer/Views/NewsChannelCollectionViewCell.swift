//
//  NewsChannelCollectionViewCell.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 09/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import UIKit
import Kingfisher

class NewsChannelCollectionViewCell: UICollectionViewCell {
    
    //MARK: - Properties
    @IBOutlet private weak var channelNameLabel: UILabel!
    @IBOutlet private weak var lastNewsLabel: UILabel!
    @IBOutlet private weak var lastNewsImageView: UIImageView!
    @IBOutlet private weak var unreadCounterLabel: UILabel!
    
    //MARK: - Setters
    func set(name: String?, lastNews: String?, imageURL: URL?, unreadCounter: Int) {
        channelNameLabel.text = name
        lastNewsLabel.text = lastNews
        
        let formatString = NSLocalizedString("unread counter", comment: "")
        unreadCounterLabel.text = String.localizedStringWithFormat(formatString, unreadCounter )
        
        guard let imageURL = imageURL else { return }
        lastNewsImageView.kf.indicatorType = .activity
        lastNewsImageView.kf.setImage(with: imageURL, placeholder: UIImage(named: "placeholder"))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lastNewsImageView.image = UIImage(named: "placeholder")
    }
}
