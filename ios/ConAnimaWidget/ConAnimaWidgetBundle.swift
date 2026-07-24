//
//  ConAnimaWidgetBundle.swift
//  ConAnimaWidget
//
//  Created by Евгений Абрамов on 24.07.2026.
//

import WidgetKit
import SwiftUI

@main
struct ConAnimaWidgetBundle: WidgetBundle {
    var body: some Widget {
        ConAnimaWidget()
        ConAnimaWidgetControl()
        ConAnimaWidgetLiveActivity()
    }
}
