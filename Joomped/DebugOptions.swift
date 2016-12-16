//
//  DebugOptions.swift
//  Notate
//
//  Created by Keith Lee on 12/16/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import Foundation
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    Swift.print(items[0], separator:separator, terminator: terminator)
    #endif
}
