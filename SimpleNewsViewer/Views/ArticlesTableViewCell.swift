//
//  ArticlesTableViewCell.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 17/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import UIKit
import Kingfisher

class ArticlesTableViewCell: UITableViewCell {

    @IBOutlet private weak var authorAndTimeLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var articleImageView: UIImageView!
    @IBOutlet private weak var isReadLabel: UILabel!
    
    func set(author: String?, publishedAt: Date, title: String, description: String?, imageURL: URL?, isRead: Bool) {
        var authorNonEmpty = NSLocalizedString("unknown", comment: "")
        if let author = author, !author.isEmpty {
            authorNonEmpty = author
        }
        var authorAndTimeString = "\(authorNonEmpty) - "
        authorAndTimeString.append(timeAgoString(from: publishedAt))
        authorAndTimeLabel.text = authorAndTimeString
        titleLabel.text = title
        descriptionLabel.text = description
        guard let imageURL = imageURL else { return }
        articleImageView.kf.indicatorType = .activity
        articleImageView.kf.setImage(with: imageURL, placeholder: UIImage(named: "placeholder"))
        isReadLabel.isHidden = isRead
    }
    
    private func timeAgoString(from date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        switch timeInterval {
        case 0..<60:
            return NSLocalizedString("Now", comment: "")
            
        case 60..<2*60:
            return NSLocalizedString("minute ago", comment: "")
            
        case 60..<60*60:
            let minutes = Int( timeInterval/60 )
            let formatString = NSLocalizedString("minutes ago", comment: "")
            return String.localizedStringWithFormat(formatString, minutes)
            
        case 60*60..<2*60*60:
            return NSLocalizedString("hour ago", comment: "")
            
        case 60*60..<24*60*60:
            let hours = Int( timeInterval/(60*60) )
            let formatString = NSLocalizedString("hours ago", comment: "")
            return String.localizedStringWithFormat(formatString, hours )
            
        case 24*60*60..<48*60*60:
            return NSLocalizedString("day ago", comment: "")
            
        default:
            let days = Int( timeInterval/(24*60*60) )
            let formatString = NSLocalizedString("days ago", comment: "")
            return String.localizedStringWithFormat(formatString, days )
        }
    }
}
