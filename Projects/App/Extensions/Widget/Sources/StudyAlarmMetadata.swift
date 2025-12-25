//
//  StudyAlarmMetadata.swift
//  Widget
//
//  Created by 영준 이 on 12/25/25.
//

import AlarmKit
import Foundation

@available(iOS 26.0, *)
struct StudyAlarmMetadata: AlarmKit.AlarmMetadata {
    let title: String
    let subtitle: String
}
