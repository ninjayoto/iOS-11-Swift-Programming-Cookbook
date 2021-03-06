//
//  AppDelegate.swift
//  Supporting File Browsing in Your App
//
//  Created by Vandad NP on 7/14/17.
//  Copyright © 2017 Pixolity Ltd. All rights reserved.
//

import UIKit
import MobileCoreServices

fileprivate extension Array where Element == String{
  static var fileTypes: [Element]{
    return [kUTTypePNG as Element]
  }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,
UIDocumentBrowserViewControllerDelegate {
  
  var window: UIWindow?
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions:
    [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    let browser = UIDocumentBrowserViewController(
      forOpeningFilesWithContentTypes: .fileTypes)
    
    browser.browserUserInterfaceStyle = .dark
    
    browser.additionalLeadingNavigationBarButtonItems = [
      UIBarButtonItem(title: "Left", style: .plain, target: self,
                      action: #selector(leftButtonPressed(_:)))
    ]
    
    browser.additionalTrailingNavigationBarButtonItems = [
      UIBarButtonItem(title: "Right", style: .plain, target: self,
                      action: #selector(rightButtonPressed(_:)))
    ]
    
    browser.delegate = self
    window?.rootViewController = browser
    
    return true
    
  }
  
  @objc func leftButtonPressed(_ sender: UIBarButtonItem){
    print("Left")
  }
  
  @objc func rightButtonPressed(_ sender: UIBarButtonItem){
    print("Right")
  }
  
  //the rest of our implementation will be written here shortly...
  
  private var documentFinder: DocumentFinder?
  private func newFileUrl(completion: @escaping (URL?) -> Void){
    
    let fileManager = FileManager()
    
    //get the url to the app's Documents folder
    guard let documentsFolder = try?
      fileManager.url(for: .documentDirectory,
                      in: .userDomainMask,
                      appropriateFor: nil, create: true) else {
                        completion(nil)
                        return
    }
    
    //create a random file name
    let randomNumber = arc4random_uniform(100)
    let fileName = "untitled\(randomNumber).png"
    let fileUrl = documentsFolder.appendingPathComponent(fileName)
    
    //find out if the file exists already in the cloud or not
    documentFinder = DocumentFinder(
    documentName: fileName){[weak self] found in
      
      guard let `self` = self else {
        completion(nil)
        return
      }
      
      self.documentFinder = nil
      
      if found{
        completion(nil)
      } else {
        completion(fileUrl)
      }
    }
    
    documentFinder?.start()
    
  }
  
  
  
  func documentBrowser(
    _ controller: UIDocumentBrowserViewController,
    didRequestDocumentCreationWithHandler importHandler:
    @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
    
    newFileUrl{[weak self] newFileUrl in
      
      guard let `self` = self else {return}
      
      //get a file URL
      guard let fileUrl = newFileUrl else {
        importHandler(nil, .none)
        controller.present(self.existingFileAlert,
                           animated: true, completion: nil)
        return
      }
      
      let document = ImageDocument(fileURL: fileUrl)
      document.save(to: fileUrl, for: .forCreating) {succeeded in
        guard succeeded else {
          importHandler(nil, .none)
          return
        }
        
        document.close{closed in
          importHandler(fileUrl, .move)
        }
        
      }
      
    }
    
  }
  
  private var existingFileAlert: UIAlertController{
    
    let message = """
I came up with a new name for this document but it
appears to already exist in your iCloud Drive.
Create a new document with a new name!
"""
    
    let controller = UIAlertController(
      title: "Existing Document",
      message: message, preferredStyle: .alert)
    
    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
    controller.addAction(action)
    
    return controller
  }
  
  func documentBrowser(_ controller: UIDocumentBrowserViewController,
                       didImportDocumentAt sourceURL: URL,
                       toDestinationURL destinationURL: URL) {
    
    let imageEditorViewController =
      ImageEditorViewController.newInstance(withFileUrl: destinationURL)
    
    controller.present(
      imageEditorViewController, animated: true, completion: nil)
    
  }
  
  func documentBrowser(_ controller: UIDocumentBrowserViewController,
                       failedToImportDocumentAt documentURL: URL, error: Error?) {
    print("Failed to import the document")
  }
  
  func documentBrowser(_ controller: UIDocumentBrowserViewController,
                       didPickDocumentURLs documentURLs: [URL]) {
    
    guard let url = documentURLs.first else {return}
    
    let imageEditorViewController =
      ImageEditorViewController.newInstance(withFileUrl: url)
    
    controller.present(
      imageEditorViewController, animated: true, completion: nil)
    
  }
  
}
