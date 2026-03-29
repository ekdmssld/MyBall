//
//  MyballWidgetBundle.swift
//  MyballWidget
//
//  Created by 정다은 on 3/23/26.
//

import WidgetKit
import SwiftUI

@main
struct MyballWidgetBundle: WidgetBundle {
    var body: some Widget {
        MyballWidget()
        MyballWidgetControl()
        MyballWidgetLiveActivity()
    }
}
