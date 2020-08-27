//
//  NewsChannelTableViewCell.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 03/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import UIKit

class NewsChannelTableViewCell: UITableViewCell {

    typealias SwitchCallback = (Bool)->()
    
    //MARK: - Properties
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    /**
        Logs constantly write warning when UISwitch change value. The problem appeared as soon as uiswitch was added in project.
        [About problem link](https://forums.raywenderlich.com/t/can-any-one-please-tell-me-if-toggle-switch-is-working-well-on-your-end/94229)
     # Warning
     ````
     invalid mode 'kCFRunLoopCommonModes'
     provided to CFRunLoopRunSpecific - break on
     _CFRunLoopError_RunCalledWithInvalidMode to debug.
     This message will only appear once per execution.
    */
    @IBOutlet private weak var switchControl: UISwitch!
    private var switchCallback: SwitchCallback!
    
    //MARK: - Setters
    func set(name: String?, description: String?, isOn: Bool, switchCallback: @escaping SwitchCallback) {
        nameLabel.text = name
        descriptionLabel.text = description
        switchControl.setOn(isOn, animated: false)
        self.switchCallback = switchCallback
    }
    
    //MARK: - Actions
    @IBAction func isAddedSwitchValueChanged(_ sender: Any) {
        switchCallback(switchControl.isOn)
    }
}
