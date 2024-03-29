//
//  Block.swift
//  RobotControl_iOS
//
//  Created by luolun on 2017/6/5.
//  Copyright © 2017年 Aaron. All rights reserved.
//

import UIKit

class Block: NSObject {
    
    let name: String
    let uuid: String
    let previousConnection: Connection?
    let nextConnection: Connection?
    
    weak var workspace: Workspace?
    
    var _variableManager: VariableManager?
    
    static let GlobalNameSpace = "Global"
    
    var directConnections: [Connection] {
        var connections = [Connection]()
        if let previousConnection = previousConnection {
            connections.append(previousConnection)
        }
        if let nextConnection = nextConnection {
            connections.append(nextConnection)
        }
        for input in inputs {
            if let blockInput = input as? BlockInput {
                connections.append(blockInput.connection)
            }
        }
        return connections
    }
    
    var blockGroup: BlockGroup?
    
    var inputs = [Input]() {
        didSet {
            for input in inputs {
                input.sourceBlock = self
                if let blockInput = input as? BlockInput {
                    blockInput.connection.sourceBlock = self
                    
                    // 如果能够容纳子Block，则这个block需要有一个变量管理器
                    _variableManager = VariableManager()
                    _variableManager!.delegate = self
                }
            }
        }
    }
    
    init(name: String, uuid: String?, previousConnection: Connection? = nil, nextConnection: Connection? = nil) {
        self.uuid = uuid ?? UUID().uuidString

        self.previousConnection = previousConnection
        self.nextConnection = nextConnection
//        workspacePosition = Workspace.Point(0, 0)
        self.name = name
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func copiedBlock() -> Block {
        let blockBuilder = BlockBuilder(name: name, hasPreviousConnection: previousConnection != nil, hasNextConnection: nextConnection != nil)
        blockBuilder.workspace = self.workspace
        
        blockBuilder.inputBuilders = [InputBuilder]()
        for input in inputs {
            let inputType: InputBuilder.InputType
            if input is FieldInput {
                inputType = .FieldInput
            } else if input is BlockInput {
                inputType = .BlockInput
            } else {
                fatalError()
            }
            
            let inputBuilder = InputBuilder(name: input.name, inputType: inputType)
            inputBuilder.fields = [Field]()
            input.fields.forEach { inputBuilder.fields?.append($0.copiedField()) }
            
            blockBuilder.inputBuilders!.append(inputBuilder)
        }
        return blockBuilder.buildBlock()
    }
    
    // MARK: Field

    func allFields() -> [Field] {
        var fields = [Field]()
        for input in inputs {
            for field in input.fields {
                fields.append(field)
            }
        }
        return fields
    }
    
    func firstFieldWith(name: String) -> Field? {
        for input in inputs {
            for field in input.fields {
                if field.name == name {
                    return field
                }
            }
        }
        return nil
    }
    
    // MAKR: - Input
    
    func firstInputWith(name: String) -> Input? {
        for input in inputs {
            if input.name == name {
                return input
            }
        }
        return nil
    }
    
    func allBlockInputs() -> [BlockInput] {
        // 效率比较低的方法，但是这个方法使用频率不高
        var blockInputs = [BlockInput]()
        for input in inputs {
            if let blockInput = input as? BlockInput {
                blockInputs.append(blockInput)
            }
        }
        return blockInputs
    }
    
    // MARK: - Debug description
    
    func debugDescription(indent: Int) -> String {
        var debugString = ""
        
        let indentString = String(repeating: "\t", count: indent)
        debugString += indentString + debugDescription
        for conn in directConnections {
            switch conn.category {
            case .previous:
                continue
            case .next:
                if let targetBlock = conn.targetBlock {
                    debugString += targetBlock.debugDescription(indent: indent)
                }
            case .child:
                if let targetBlock = conn.targetBlock {
                    debugString += targetBlock.debugDescription(indent: indent + 1)
                }
            }
        }
        return debugString
    }
    
    // MARK: - Variable
    
    func parentBlock() -> Block? {
        var block: Block? = self
        while block != nil {
            if let targetCategory = block?.previousConnection?.targetConnection?.category,
                let targetBlock = block?.previousConnection?.targetBlock,
                targetCategory == .child {
                return targetBlock
            }
            
            block = block!.previousConnection?.targetBlock
        }
        return nil
    }
    
    func firstBlockInSameLevel() -> Block {
        var block = self
        while true {
            if let previousConnection = block.previousConnection
            , let previous = previousConnection.targetBlock,
                previousConnection.targetConnection?.category == .next {
                block = previous
            } else {
                return block
            }
        }
    }
    
    func orderInSameLevel() -> Int {
        let firstInSameLevel = firstBlockInSameLevel()
        var i = 0
        var block = self
        while block != firstInSameLevel {
            block = block.previousConnection!.targetBlock!
            i += 1
        }
        return i
    }
    
    func variableManager() -> VariableManager {
        var block: Block? = self
        while block != nil {
            if block!._variableManager != nil {
                return block!._variableManager!
            }
            block = block!.parentBlock()
        }
        
        return workspace!.variableManager
    }
}

extension Block: VariableManagerDelegate {
    func namespace() -> String {
        var block: Block? = self
        var namespaces = [String]()
        while block != nil {
            namespaces.append(block!.name + String(block!.orderInSameLevel()))
            block = block?.parentBlock()
        }
        namespaces.append(Block.GlobalNameSpace)
        let namespace = namespaces.reversed().joined(separator: ".")
        return namespace
    }
}
