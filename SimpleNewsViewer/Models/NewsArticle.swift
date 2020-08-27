//
//  NewsArticle.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 26/07/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation
import CoreData

@objc(NewsArticle)
protocol NewsArticle: NSFetchRequestResult {
    var title: String { get }
    var author: String? { get }
    var publishedAt: Date { get }
    var content: String? { get }
    var imageURL: URL? { get }
    var sourceID: String? { get }
    var url: URL? { get }
    var isRead: Bool { get }
}
