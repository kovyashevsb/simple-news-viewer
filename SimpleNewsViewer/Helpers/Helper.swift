//
//  Helper.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 26/05/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation
import CoreData

extension String {
    var toInternetURL: URL? {
        let url = self.toURL
        if url?.scheme?.hasPrefix("http") == true {
            return url
        }
        return nil
    }
    var toURL: URL? {
        return URL(string: self)
    }
}

extension NSManagedObject {
    static func fetchRequest<T>() -> NSFetchRequest<T> {
        NSFetchRequest<T>(entityName: self.entity().name!)
    }
    
    static func batchUpdateRequest() -> NSBatchUpdateRequest {
        NSBatchUpdateRequest(entityName: self.entity().name!)
    }
    
    static func fetchedResultsController<T: NSManagedObject>(with context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]) -> NSFetchedResultsController<T> {
        let request: NSFetchRequest<T> = fetchRequest()
        request.sortDescriptors = sortDescriptors
        return NSFetchedResultsController(fetchRequest: request,
                                          managedObjectContext: context,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }
}

extension KeyPath where Root: NSObject {
    var toString: String {
        return NSExpression(forKeyPath: self).keyPath
    }
}
