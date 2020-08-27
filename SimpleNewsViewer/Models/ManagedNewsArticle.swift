//
//  ManagedNewsArticle.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 17/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation
import CoreData

@objc(ManagedNewsArticle)
class ManagedNewsArticle: NSManagedObject, NewsArticle {
    
    @NSManaged var title: String
    @NSManaged var author: String?
    @NSManaged var publishedAt: Date
    @NSManaged var content: String?
    @NSManaged var imageURL: URL?
    @NSManaged var sourceID: String?
    @NSManaged var url: URL?
    @NSManaged var isRead: Bool
}
