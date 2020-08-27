//
//  ErrorLabel.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 20/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import UIKit

class ErrorLabel: UILabel {

    func set(with error: NewsModelError) {
        switch error {
        case .server:
            text = NSLocalizedString("server error", comment: "")
        case .network:
            text = NSLocalizedString("network error", comment: "")
        case .decoding:
            text = NSLocalizedString("decoding error", comment: "")
        }
    }

}
