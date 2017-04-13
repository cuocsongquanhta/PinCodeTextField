//
//  PinCodeTextField.swift
//  PinCodeTextField
//
//  Created by Alexander Tkachenko on 3/15/17.
//  Copyright © 2017 organization. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable public class PinCodeTextField: UIView {
    public weak var delegate: PinCodeTextFieldDelegate?
    
    //MARK: Customizable from Interface Builder
    @IBInspectable public var underlineWidth: CGFloat = 40
    @IBInspectable public var underlineHSpacing: CGFloat = 10
    @IBInspectable public var underlineVMargin: CGFloat = 0
    @IBInspectable public var characterLimit: Int = 5
    @IBInspectable public var underlineHeight: CGFloat = 3
    @IBInspectable public var placeholderText: String?
    @IBInspectable public var text: String?
    
    @IBInspectable public var fontSize: CGFloat = 14 {
        didSet {
            font = font.withSize(fontSize)
        }
    }
    @IBInspectable public var textColor: UIColor = UIColor.clear 
    @IBInspectable public var placeholderColor: UIColor = UIColor.lightGray
    @IBInspectable public var underlineColor: UIColor = UIColor.darkGray
    @IBInspectable public var secureText: Bool = false
    
    //MARK: Customizable from code
    public var keyboardType: UIKeyboardType = UIKeyboardType.alphabet
    public var font: UIFont = UIFont.systemFont(ofSize: 14)
    public var allowedCharacterSet: CharacterSet = CharacterSet.alphanumerics
    
    public var isSecureTextEntry: Bool {
        get {
            return secureText
        }
        @objc(setSecureTextEntry:) set {
            secureText = newValue
        }
    }
    
    //MARK: Private
    fileprivate var labels: [UILabel] = []
    fileprivate var underlines: [UIView] = []
    
    
    //MARK: Init and awake
    override init(frame: CGRect) {
        super.init(frame: frame)
        postInitialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        postInitialize()
    }
    
    override public func prepareForInterfaceBuilder() {
        postInitialize()
    }
    
    private func postInitialize() {
        updateView()
    }
    
    //MARK: Overrides
    override public func layoutSubviews() {
        layoutCharactersAndPlaceholders()
        super.layoutSubviews()
    }
    
    override public var canBecomeFirstResponder: Bool {
        return true
    }
    
    override public func becomeFirstResponder() -> Bool {
        delegate?.textFieldDidBeginEditing(self)
        return super.becomeFirstResponder()
    }
    
    override public func resignFirstResponder() -> Bool {
        delegate?.textFieldDidEndEditing(self)
        return super.resignFirstResponder()
    }
    
    //MARK: Private
    fileprivate func updateView() {
        if (needToRecreateUnderlines()) {
            recreateUnderlines()
        }
        if (needToRecreateLabels()) {
            recreateLabels()
        }
        updateLabels()
        setNeedsLayout()
    }
    
    private func needToRecreateUnderlines() -> Bool {
        return characterLimit != underlines.count
    }
    
    private func needToRecreateLabels() -> Bool {
        return characterLimit != labels.count
    }
    
    private func recreateUnderlines() {
        underlines.forEach{ $0.removeFromSuperview() }
        underlines.removeAll()
        characterLimit.times {
            let underline = createUnderline()
            underlines.append(underline)
            addSubview(underline)
        }
    }
    
    private func recreateLabels() {
        labels.forEach{ $0.removeFromSuperview() }
        labels.removeAll()
        characterLimit.times {
            let label = createLabel()
            labels.append(label)
            addSubview(label)
        }
    }
    
    private func updateLabels() {
        let textHelper = TextHelper(text: text, placeholder: placeholderText, isSecure: isSecureTextEntry)
        for label in labels {
            let index = labels.index(of: label) ?? 0
            let currentCharacter = textHelper.character(atIndex: index)
            label.text = currentCharacter.map { String($0) }
            label.font = font
            let isplaceholder = isPlaceholder(index)
            label.textColor = labelColor(isPlaceholder: isplaceholder)
        }
    }
    
    private func labelColor(isPlaceholder placeholder: Bool) -> UIColor {
        return placeholder ? placeholderColor : textColor
    }
    
    private func isPlaceholder(_ i: Int) -> Bool {
        let inputTextCount = text?.characters.count ?? 0
        return i >= inputTextCount
    }
    
    private func createLabel() -> UILabel {
        let label = UILabel(frame: CGRect())
        label.font = font
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        return label
    }
    
    private func createUnderline() -> UIView {
        let underline = UIView()
        underline.backgroundColor = underlineColor
        return underline
    }
    
    private func layoutCharactersAndPlaceholders() {
        let marginsCount = characterLimit - 1
        let totalMarginsWidth = underlineHSpacing * CGFloat(marginsCount)
        let totalUnderlinesWidth = underlineWidth * CGFloat(characterLimit)
        
        var currentLabelX: CGFloat = bounds.width / 2 - (totalUnderlinesWidth + totalMarginsWidth) / 2
        var currentUnderlineX = currentLabelX
        let totalLabelHeight = font.ascender + font.descender
        let underlineY = bounds.height / 2 + totalLabelHeight / 2 + underlineVMargin
        
        underlines.forEach{
            $0.frame = CGRect(x: currentUnderlineX, y: underlineY, width: underlineWidth, height: underlineHeight)
            currentUnderlineX += underlineWidth + underlineHSpacing
        }
        
        labels.forEach {
            $0.frame = CGRect(x: currentLabelX, y: 0, width: underlineWidth, height: bounds.height)
            currentLabelX += underlineWidth + underlineHSpacing
        }
        
    }
    
    //MARK: Touches
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let location = touch.location(in: self)
        if (bounds.contains(location)) {
            if (delegate?.textFieldShouldBeginEditing(self) ?? true) {
                let _ = becomeFirstResponder()
            }
        }
    }
    
    
    //MARK: Text processing
    func canInsertCharacter(_ character: String) -> Bool {
        let newText = text.map { $0 + character } ?? character
        let isNewline = character.hasOnlyNewlineSymbols
        let isCharacterMatchingCharacterSet = character.trimmingCharacters(in: allowedCharacterSet).isEmpty
        let isLengthWithinLimit = newText.characters.count <= characterLimit
        return !isNewline && isCharacterMatchingCharacterSet && isLengthWithinLimit
    }
}


//MARK: UIKeyInput
extension PinCodeTextField: UIKeyInput {
    public var hasText: Bool {
        if let text = text {
            return !text.isEmpty
        }
        else {
            return false
        }
    }
    
    public func insertText(_ charToInsert: String) {
        if charToInsert.hasOnlyNewlineSymbols {
            if (delegate?.textFieldShouldReturn(self) ?? true) {
                let _ = resignFirstResponder()
            }
        }
        else if canInsertCharacter(charToInsert) {
            let newText = text.map { $0 + charToInsert } ?? charToInsert
            text = newText
            updateView()
            delegate?.textFieldValueChanged(self)
            if (newText.characters.count == characterLimit) {
                if (delegate?.textFieldShouldEndEditing(self) ?? true) {
                    let _ = resignFirstResponder()
                }
            }
        }
    }
    
    public func deleteBackward() {
        guard hasText else { return }
        text?.characters.removeLast()
        updateView()
        delegate?.textFieldValueChanged(self)
    }
}
