//
//  ViewController.swift
//  Project25
//
//  Created by Sabrina Fletcher on 5/30/18.
//  Copyright © 2018 Sabrina Fletcher. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate{
    var images = [UIImage]()
    var beacons = [String]()
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        title = "Selfie Share"
        //adds a right bar button item that uses camera icon
        //navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))]
        //UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(beaconList))
        //navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        //initializes our MCSession in order to make connections
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
    }
    

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)
        
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.item]
        }
        return cell
    }
    
    
    @IBAction func importPicture(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        let ac = UIAlertController(title: "Import Picture From...", message: nil, preferredStyle: .actionSheet)
        if(UIImagePickerController.isSourceTypeAvailable(.camera)){
            ac.addAction(UIAlertAction(title: "Camera", style: .default){
                (alert) -> Void in
                picker.sourceType = .camera
                picker.modalPresentationStyle = .fullScreen
                self.present(picker, animated: true, completion: nil)
                
            })
        }
        
        ac.addAction(UIAlertAction(title: "Select photo from Library", style: .default) {
            (alert) -> Void in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: nil)
        })
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let popOverController = ac.popoverPresentationController{
            popOverController.barButtonItem = self.navigationItem.rightBarButtonItem
        }
        
        present(ac, animated: true)
        
        
    }
    
    
//    @objc func importPicture() {
//        //print("Import picture worked")
//        let picker = UIImagePickerController()
//        picker.allowsEditing = true
//        picker.delegate = self
//        let ac = UIAlertController(title: "Import Picture From...", message: nil, preferredStyle: .actionSheet)
//        if(UIImagePickerController.isSourceTypeAvailable(.camera)){
//            ac.addAction(UIAlertAction(title: "Camera", style: .default){
//                (alert) -> Void in
//                picker.sourceType = .camera
//                picker.modalPresentationStyle = .fullScreen
//                self.present(picker, animated: true, completion: nil)
//
//            })
//        }
//        ac.addAction(UIAlertAction(title: "Select photo from Library", style: .default) {
//            (alert) -> Void in
//            picker.sourceType = .photoLibrary
//            self.present(picker, animated: true, completion: nil)
//        })
//        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//        if let popOverController = ac.popoverPresentationController{
//            popOverController.barButtonItem = self.navigationItem.rightBarButtonItem
//        }
//
//        present(ac, animated: true)
//
//    }
    
    @IBAction func showConnectionPrompt(_ sender: UIBarButtonItem) {
        print("Connection Prompt Reached")
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        //need to do this to display a popover view in an iPad
        ac.popoverPresentationController?.sourceView = self.view
        present(ac, animated: true)
        
    }
    
//    @objc func showConnectionPrompt() {
//        print("Connection Prompt Reached")
//        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
//        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
//        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
//        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        //need to do this to display a popover view in an iPad
//        ac.popoverPresentationController?.sourceView = self.view
//        present(ac, animated: true)
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? beaconListVC {
            print("Array passed")
            //passes the list of connected beacons to the beacon VC
            vc.beaconList = beacons
        }
    }
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else {return}
        
        dismiss(animated: true)
        images.insert(image, at: 0)
        collectionView?.reloadData()
        
        //1, check if there are any peers to send to
        if mcSession.connectedPeers.count > 0 {
            //2, convert the new image to a Data object
            if let imageData = UIImagePNGRepresentation(image){
                //3, send it to all peers, ensuring it gets delivered
                do{
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch{
                    //4, shows an error message if there's a problem
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
            
            
        }
    
    }
    
    func startHosting(action: UIAlertAction) {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-project25", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }
    
    func joinSession(action: UIAlertAction){
        let mcBrowser = MCBrowserViewController(serviceType: "hws-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }

    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        //diagnostic information that lets you know if you are connected to a session, disconnected or in the process of connecting
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            beacons.append(peerID.displayName)
            
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
            if let index = beacons.index(of: peerID.displayName){
                beacons.remove(at: index)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let image = UIImage(data: data){
            DispatchQueue.main.async {
                [unowned self] in
                self.images.insert(image, at: 0)
                self.collectionView?.reloadData()
            }
        }
    }

}

