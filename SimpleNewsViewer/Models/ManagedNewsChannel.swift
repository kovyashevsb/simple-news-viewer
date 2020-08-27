//
//  ManagedNewsChannel.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 23/07/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation
import CoreData

@objc(ManagedNewsChannel)
class ManagedNewsChannel: NSManagedObject, NewsChannel {
    
    @NSManaged dynamic var isEnabled: Bool
    @NSManaged dynamic var id: String
    @NSManaged dynamic var name: String
    @NSManaged dynamic var about: String
    @NSManaged dynamic var lastArticle: ManagedNewsArticle?
    var lastNews: NewsArticle? { lastArticle }
    
    static func == (lhs: ManagedNewsChannel, rhs: ManagedNewsChannel) -> Bool {
        return lhs.id == rhs.id
    }
}
