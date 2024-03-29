//
//  TranslateInteractor.swift
//  translate_viper_test
//
//  Created by Denis on 16/07/2019.
//  Copyright © 2019 hostis. All rights reserved.
//

import Foundation

protocol TranslateInteractorProtocol: class {
	
	var presenter: TranslatePresenterProtocol? { get set }
	
	func translate(text: String, direction: Direction,completion: @escaping (String?)->())
}

class TranslateInteractor: TranslateInteractorProtocol {
	
	weak var presenter: TranslatePresenterProtocol?
	
	var text: String?
	
	func translate(text: String, direction: Direction,completion: @escaping (String?) -> ()) {
		APIManager.translate(text: text, direction: direction) { [weak self] (json) in
			guard let self = self else { return }
			if let code = json["code"] as? Int, code == 200 {
				
				if let text = json["text"] as? [String] {
					var finalText = ""
					text.forEach({ (item) in
						finalText += "\(item)"
					})
					self.text = finalText
				}
			} else {
				print("error while translating")
			}
			if let translation = self.text, !translation.isEmpty {
				self.saveTranslationInDatabase(primary: text, secondary: translation, direction: direction)
			}
			completion(self.text)
		}
	}
	
	func saveTranslationInDatabase(primary: String, secondary: String, direction: Direction) {
		
		// do not save translation if it the same as original word
		guard primary != secondary, let primaryCode = direction.primary.code, let secondaryCode = direction.secondary.code else { return }
		
		if let translationInCoreData = Dict.getTranslation(origin: primary, primaryLang: primaryCode, secondaryLang: secondaryCode) {
			if translationInCoreData.secondaryWord == secondary {
				print("already in database word: \(primary), translation: \(secondary)")
				return
			} else {
				translationInCoreData.secondaryWord = secondary
				CoreDataManager.instance.saveContext()
				print("saved word: \(primary), translation: \(secondary)")
			}
		} else {
			let translation = Dict(context: CoreDataManager.instance.context)
			translation.primaryWord = primary
			translation.secondaryWord = secondary
			translation.primaryLang = String(direction.primary.code ?? "")
			translation.secondaryLang = String(direction.secondary.code ?? "")
			
			CoreDataManager.instance.saveContext()
			print("saved word: \(primary), translation: \(secondary)")
		}
		
		
		
	}
}
