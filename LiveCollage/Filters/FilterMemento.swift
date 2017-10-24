//
//  FilterMemento.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 15/09/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import Foundation
import CoreImage

//: Show memento
protocol Memento {
    
}

//: The originator can create and restore game state
protocol Originator {
    func createMemento() -> Memento
    func applyMemento(memento: Memento)
}

//: an applied filter
struct FilterStateEntry {
    var filter: CIFilter
    var value: CGFloat
    var depthEnabled: Bool
    var valueDepth: CGFloat
    var valueSlope: CGFloat
    var background: Bool
    
    
    func isType(name: String) -> Bool {
        return self.filter.name.elementsEqual(name)
    }
}

//: A Filter memento, which contains all the information the Filter needs to restore the image
struct FilterMemento: Memento {
    private let entries: [FilterStateEntry]
    private let nextId: Int
    
    init(state: FilterState){
        self.entries = state.entries
        self.nextId = state.nextId
    }
    func apply(state: FilterState) {
        print("Restoring a filter state to a previous state...")
        state.nextId = nextId
        state.entries = entries
    }
}

//: A CheckPoint can create and restore game state
class FilterState: Originator {
    var entries: [FilterStateEntry] = []
    var nextId: Int = 0
    
    func addFilterStateEntry(filter: CIFilter, value: CGFloat, depthEnabled: Bool, depth: CGFloat, slope: CGFloat, background: Bool) {
        let entry = FilterStateEntry(filter: filter, value: value, depthEnabled: depthEnabled, valueDepth: depth, valueSlope: slope, background: background)
        entries.append(entry)
        nextId = nextId + 1
    }
    
    func createMemento() -> Memento {
        return FilterMemento(state: self)
    }
    
    func applyMemento(memento: Memento) {
        guard let m = memento as? FilterMemento  else { return }
        m.apply(state: self)
    }
    
    func printCheckPoint() {
        print("Printing filters....")
        for entry in entries {
            print("Filter: \(entry.filter), Value: \(entry.value), Depth Value: \(entry.valueDepth)")
        }
        print("Total filters: \(entries.count)\n")
        
    }
}

//Utility Methods
extension FilterState {
    
    func getStateForFilter(name: String) -> FilterStateEntry? {
        for entry in entries {
            if entry.isType(name: name) {
                Logger.log(type: .DEBUG, string: "Filter found with name \(name)")
                return entry
            }
        }
        Logger.log(type: .DEBUG, string: "No filter found with name \(name)")
        return nil
    }
    
    func removeFilter(filterName: String) {
        var position = 0
        var found = false
        for entry in entries {
            if entry.isType(name: filterName) {
                found = true
                break
            }
            position = position + 1
        }
        
        if found {
            removeFilter(index: position)
        }
    }
    
    private func removeFilter(index: Int) {
        Logger.log(type: .DEBUG, string: "Removing filter at index \(index)")
        entries.remove(at: index)
    }
    
    func removeLast() {
        if entries.count < 1 {
            Logger.log(type: .DEBUG, string: "Attempted to undo filter but no filter is applied!!")
            return
        }
        Logger.log(type: .DEBUG, string: "Removing filter at index \(entries.count)")
        entries.remove(at: entries.count)
    }
    
    func replaceEntry(filter: CIFilter, value: CGFloat, depthEnabled: Bool, valueDepth: CGFloat, valueSlope: CGFloat, background: Bool) {
        var position = 0
        var found = false
        for entry in entries {
            if entry.isType(name: filter.name) {
                found = true
                break
            }
            position = position + 1
        }
        if found {
            entries[position] = FilterStateEntry(filter: filter, value: value, depthEnabled: depthEnabled, valueDepth: valueDepth, valueSlope: valueSlope, background: background)
        }
    }
    
}
