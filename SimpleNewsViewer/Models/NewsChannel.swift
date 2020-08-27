//
//  NewsChannel.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 03/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation
import CoreData

@objc(NewsChannel)
protocol NewsChannel: NSFetchRequestResult {
    typealias UID = String
    
    var id: UID { get }
    var isEnabled: Bool { get }
    var name: String { get }
    var about: String { get }
    var lastNews: NewsArticle? { get }
}
