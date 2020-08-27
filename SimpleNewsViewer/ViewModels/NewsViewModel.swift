//
//  NewsViewModel.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 16/06/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation

enum NewsViewModelState
{
  struct Item
  {
    let title: String
    let author: String?
    let publishedAt: Date
    let description: String?
    let imageURL: URL?
    let url: URL?
    let isRead: Bool
  }

  case items(items:[Item])
  case noItems(message:String)
  case failure(error: NewsModelError)
}

protocol NewsViewModel
{
  var state : NewsViewModelState { get }
  var onChangeState:((_ newState:NewsViewModelState)->Void)? { set get }
  var onLoading:((_ isLoading:Bool)->Void)? { set get }
  func refresh()
  
  ///Mark as read all articles for current `mode`
  func markAsRead()
  func markAsRead(article withUrl: URL)
}
