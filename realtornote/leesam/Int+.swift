//
//  Int+.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 26..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

extension Int{
    var roman : String{
        get{
            let romans : [String] = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];
            var value = romans[self % romans.count - 1];
            
            return value;
        }
    }
    
    var alpha : String{
        get{
            let alphas : [String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
                "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"];
            var value = alphas[self % alphas.count - 1];
            
            return value;
        }
    }
    
    init(alpha: String) {
        let alphas : [String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
                                 "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"];
        
        self = (alphas.index(of: alpha) ?? -1) + 1;
    }
}

extension Int32{
    var roman : String{
        get{
            let romans : [String] = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];
            var value = romans[Int(self % 10 - 1)];
            
            return value;
        }
    }
}

extension Int16{
    var roman : String{
        get{
            let romans : [String] = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];
            var value = romans[Int(self % 10 - 1)];
            
            return value;
        }
    }
}
