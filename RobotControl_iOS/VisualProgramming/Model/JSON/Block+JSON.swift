//
//  Block+JSON.swift
//  RobotControl_iOS
//
//  Created by luolun on 2017/6/7.
//  Copyright © 2017年 Aaron. All rights reserved.
//

import Foundation

/**
 *  Construct a block builder from json definition
 */
extension Block {
    
    public class func makeBuilder(json: [String: Any]) throws -> BlockBuilder {
        guard let name = json["name"] as? String else {
            throw BlockJsonError("Name missed or had wrong format.")
        }
        
        if name == Block.GlobalNameSpace {
            throw BlockJsonError("`Global` is reserved word, and cannot be the name of block.")
        }
        
        guard let inputsJson = json["inputs"] as? Array<[String: Any]> else {
            throw BlockJsonError("Input list missed or had wrong format.")
        }
        
        var inputBuilders = [InputBuilder]()
        for inputJson in inputsJson {
            guard let inputTypeString = inputJson["type"] as? String else {
                throw BlockJsonError("Input type missed or had wrong format.")
            }
            
            let inputName = inputJson["name"] as? String ?? ""
            
            guard let fieldsJson = inputJson["fields"] as? Array<[String: Any]> else {
                throw BlockJsonError("Fields list missed or had wrong format.")
            }
            
            let inputType: InputBuilder.InputType
            switch inputTypeString {
            case "field_input":
                inputType = .FieldInput
            case "block_input":
                inputType = .BlockInput
            default:
                throw BlockJsonError("Unknown input type \(inputTypeString)")
            }
            
            let inputBuilder = InputBuilder(name: inputName, inputType: inputType)
            var fields = [Field]()
            for fieldJson in fieldsJson {
                guard let fieldTypeString = fieldJson["type"] as? String else {
                    throw BlockJsonError("Missing field type or it has wrong format.")
                }
                
                let fieldName = fieldJson["name"] as? String ?? ""
                let field: Field
                switch fieldTypeString {
                case "field_label":
                    field = try fieldLabel(with: fieldJson, name: fieldName)
                case "field_variable":
                    field = FieldVariable(name: fieldName)
                default:
                    throw BlockJsonError("Unknown field type \(fieldTypeString)")
                }
                
                fields.append(field)
            }
            inputBuilder.fields = fields
            
            inputBuilders.append(inputBuilder)
        }
        
        let hasPreviousStatement = (json["has_previous_statement"] as? String) == "true"
        let hasNextStatement = (json["has_next_statement"] as? String) == "true"
        
        let builder = BlockBuilder(name: name, hasPreviousConnection: hasPreviousStatement, hasNextConnection: hasNextStatement)
        builder.inputBuilders = inputBuilders
        
        return builder
    }
 
    // MARK: - Field
    
    class func fieldLabel(with fieldJson: [String: Any], name: String) throws -> FieldLabel {
        guard let text = fieldJson["text"] as? String else {
            throw BlockJsonError("Field label msut have a `test` item.")
        }
        
        let fieldLabel = FieldLabel(name: name, text: text)
        return fieldLabel
    }
}

class BlockJsonError: NSError {
    init(_ description: String) {
        super.init(domain: "BlockJsonError", code: -1, userInfo: [NSLocalizedDescriptionKey: description])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
