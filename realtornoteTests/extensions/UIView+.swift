//
//  UIView+.swift
//  realtornoteTests
//
//  Created by 영준 이 on 2023/11/30.
//  Copyright © 2023 leesam. All rights reserved.
//

import XCTest
import Quick
import Nimble

final class UIViewExtensionTests: QuickSpec {
    override class func spec() {
        describe("IgnoresDarkMode") {
            lazy var view: UIView = { UIView() }()
            
            it("accessibilityIgnoresInvertColors is true, if mode is true") {
                view.ignoresDarkMode = true
                
                expect(view.accessibilityIgnoresInvertColors).to(equal(true))
            }
            
            it("accessibilityIgnoresInvertColors is false, if mode is false") {
                view.ignoresDarkMode = false
                
                expect(view.accessibilityIgnoresInvertColors).to(equal(false))
            }
        }
    }
}
