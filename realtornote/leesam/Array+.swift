//
//  Array+.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 8. 15..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

extension Array{
    var any : Bool{
        get{
            return !self.isEmpty;
        }
    }
    
    func takeFirst(_ n: Int) -> ArraySlice<Element>{
        //return self.dropLast(self.);
        var values : ArraySlice<Element> = [];
        
        for element in self{
            if self.count >= n{
                break;
            }
            
            values.append(element);
        }
        
        return values;
    }
    
    func takeLast(_ n: Int) -> ArraySlice<Element>{
        return self.dropFirst(Swift.max(self.count - n, 0));
    }
    
    var random : Element?{
        get{
            return self.takeRandom(1).first;
        }
    }
    func takeRandom(_ n:Int) -> ArraySlice<Element>{
        var values : ArraySlice<Element> = [];
        var valueSet : [Int] = [];
        
        for _ in 0..<Swift.min(n, self.count){
            var value : Element
            
            repeat{
                let index = Int(arc4random_uniform(UInt32(self.count)));
                value = self[index];
                if !valueSet.contains(index) {
                    values.append(value);
                    valueSet.append(index);
                    break;
                }
            }while(true);
        }
        
        return values;
    }
    
    @discardableResult
    mutating func remove(_ item : Element, where predicate: (Element, Element) throws -> Bool) rethrows -> Bool{
        var i = 0;
        var value = false;
        
        for element in self{
            if try predicate(element, item) {
                self.remove(at: i);
                value = true;
                break;
            }
            
            i = i + 1;
        }
        
        return value;
    }
    
    mutating func suffled(where predicate: (Element, Element) throws -> Bool) rethrows{
        self = try self.suffle(where: predicate);
    }
    
    func suffle(where predicate: (Element, Element) throws -> Bool) rethrows -> [Element]{
        var values : [Element] = [];
        var copies = self;
        
        while(values.count < self.count){
            let value = copies.random;
            values.append(value!);
            try copies.remove(value!, where: predicate);
        }
        
        return values;
    }
}
