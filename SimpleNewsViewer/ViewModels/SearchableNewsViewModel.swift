//
//  SearchableNewsViewModel.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 16/06/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation
import RxSwift

protocol SearchableNewsViewModel : NewsViewModel
{
  func searchNews(withKeywords keywords:String)
    //Rx
    func searchArticles(withKeywords keywords: String) -> Single<NewsViewModelState>
}
