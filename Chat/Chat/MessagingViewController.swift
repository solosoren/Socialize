//
//  MessagingViewController.swift
//  Chat
//
//  Created by Soren Nelson on 4/1/16.
//  Copyright © 2016 SORN. All rights reserved.
//

import UIKit
import CloudKit

class MessagingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    
    @IBOutlet weak var tableView: TableView!
    @IBOutlet var keyboardInputView: UIView!
    @IBOutlet var keyboardView: UIView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet var constraint: NSLayoutConstraint!
    @IBOutlet var keyboardViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var sendButton: UIButton!
    var conversation: Conversation?
    var convoRecord: CKRecord?
    var demo = false
    var skippedLogin = false
    var newConstraint: NSLayoutConstraint?
    var grouped = false
    var newConvo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorColor = UIColor.white
        messageTextView.delegate = self
        sendButton.layer.borderColor = UIColor.white.cgColor
        sendButton.layer.borderWidth = 1.0
        setNavBar()
        sendButton.isEnabled = false

        NotificationCenter.default.addObserver(self, selector: #selector(MessagingViewController.keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MessagingViewController.keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
        
    
    
//    MARK: Tableview
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let conversation = conversation {
            return conversation.theMessages.count
            
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
//    fix message record
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let themMessageCell = tableView.dequeueReusableCell(withIdentifier: "themMessageCell", for: indexPath) as! ThemMessageTableViewCell
        let meMessageCell = tableView.dequeueReusableCell(withIdentifier: "meMessageCell", for: indexPath) as! MeMessageTableViewCell
        
//    fix
        if let conversation = conversation {
            
            let message = conversation.theMessages[(indexPath as NSIndexPath).row]
            
            if message.senderUID == UserController.sharedInstance.myRelationship?.userID {
                meMessageCell.messageText.text = message.messageText
                if let image = message.userPic {
                    meMessageCell.userIcon.image = image
                } else {
                    meMessageCell.userIcon?.image = UIImage(named: "Contact")
                }
                return meMessageCell
            } else {
                themMessageCell.messageText.text = message.messageText
                if let image = message.userPic {
                    themMessageCell.userIcon.image = image
                } else {
                    themMessageCell.userIcon?.image = UIImage(named: "Contact")
                }
                return themMessageCell
            }
        } else if demo {
            return themMessageCell
        } else if skippedLogin {
            themMessageCell.messageText.text = "Create an account to get started socializing."
            return themMessageCell
        } else {
            themMessageCell.messageText.text = "Loading..."
            return themMessageCell
        }
    }
    
    func keyboardWasShown(_ notification: Notification) {
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            constraint.constant = keyboardSize.height
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.layoutIfNeeded()
            }) 
        }
        tableView.reloadData(conversation)
    }
    
    func keyboardWillBeHidden(_ notification: Notification) {
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if constraint.constant != 52 {
                self.constraint.constant -= keyboardSize.height
            }
        }
        keyboardViewHeightConstraint.constant = messageTextView.frame.size.height + 14
        resignFirstResponder()
        tableView.reloadData(conversation)
    }
    
//    MARK: Input Accessory View
    override var inputAccessoryView: UIView {
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.layoutIfNeeded()
        
        let fixedWidth = messageTextView.frame.size.width
        let newSize = messageTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = messageTextView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        messageTextView.frame = newFrame

//        keyboardView.frame.size.height = self.messageTextView.frame.size.height + 14
        keyboardViewHeightConstraint.constant = messageTextView.frame.size.height + 14
        keyboardView.autoresizingMask = .flexibleHeight
        return keyboardInputView
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if messageTextView.text.isEmpty {
            sendButton.isEnabled = false
        } else {
            sendButton.isEnabled = true
        }
        if messageTextView.contentSize.height > 200 {
            messageTextView.frame.size.height = 200
        }
        DispatchQueue.main.async { 
            if self.keyboardView.frame.size.height != self.messageTextView.frame.size.height + 14 {
                self.keyboardViewHeightConstraint.constant = self.messageTextView.frame.size.height + 14
                self.reloadInputViews()
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        tableView.reloadData(conversation)
        constraint.constant = keyboardView.frame.size.height + 2
    }
    
    
//    MARK: Send Button
    @IBAction func sendMessageTapped(_ sender: AnyObject) {
        var message: Message
        
        if messageTextView.text.isEmpty == false {
            let userpic = UserController.sharedInstance.myRelationship?.profilePic?.image
            
            message = Message(senderUID: UserController.sharedInstance.myRelationship!.userID, messageText: messageTextView.text, time: nil, userPic: userpic)
            
            MessageController.postMessage(message) { (success, messageRecord) in
                if success {
                    if let record = self.convoRecord, let conversation = self.conversation {
                        let ref = CKReference(record: messageRecord!, action: .deleteSelf)
                        message.timeString = Timer.sharedInstance.setMessageTime((messageRecord?.creationDate)!)
                        message.time = messageRecord?.creationDate
                        if conversation.messages != nil && conversation.messages?.count != 0 {
                            var messages = record["Messages"] as! [CKReference]
                            messages += [ref]
                            record.setValue(messages, forKey: "Messages")
                            let mod = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
                            
                            mod.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                                if error == nil {
                                    if conversation.theMessages.isEmpty == true {
                                        ConversationController.sharedInstance.subscribeToConversations(self.convoRecord!, contentAvailable: true, completion: { (success) in
                                        })
                                    }
                                    DispatchQueue.main.async(execute: {
                                        self.messageTextView.text = ""
                                        self.keyboardView.frame.size.height = self.messageTextView.frame.size.height + 14
                                        self.conversation?.theMessages += [message]
                                        self.conversation?.lastMessage = message
                                        self.conversation?.messages = messages
                                        self.keyboardViewHeightConstraint.constant = self.messageTextView.frame.size.height + 14
                                        
                                        self.tableView.reloadData(self.conversation)
                                        self.resignFirstResponder()
                                    })
                                } else {
                                    print("ERROR SAVING MESSAGES TO CONVO: \(error!.localizedDescription)")
                                }
                            }
                            CKContainer.default().publicCloudDatabase.add(mod)
                            
                        } else {
                            let messages = [ref]
                            record.setValue(messages, forKey: "Messages")
                            let mod = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
                            mod.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                                if error == nil {
                                    print(message.senderUID)
                                    DispatchQueue.main.async(execute: {
                                        self.messageTextView.text = ""
                                        self.conversation?.messages! = messages
                                        self.conversation?.theMessages = [message]
                                        self.conversation?.lastMessage = message
                                        self.tableView.reloadData(self.conversation)
                                    })
                                } else {
                                    print("ERROR SAVING MESSAGES TO CONVO: \(error!.localizedDescription)")
                                }
                            }
                            CKContainer.default().publicCloudDatabase.add(mod)
                        }
                    }
                } else {
                    print("Not this time")
                }
            }
        }
    }
    
    @IBAction func backButton(_ sender: AnyObject) {
        if grouped {
            performSegue(withIdentifier: "groupUnwind", sender: self)
        } else {
            performSegue(withIdentifier: "messageUnwind", sender: self)
        }
    }
    
    override func unwind(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
        
        if unwindSegue.identifier == "messageUnwind" {
            let destinationVC = unwindSegue.destination as! HomeViewController
            
            guard let conversation = conversation else {
                return
            }
            
            var messages = false
            if conversation.theMessages.count > 0 {
                messages = true
            }
            if let homeConvos = destinationVC.myConversations {
                if messages {
                    
                        if homeConvos.count > 0 {
                            
                            if newConvo {
                                destinationVC.myConversations?.insert(conversation, at: 0)
                                destinationVC.convoRecords?.insert(convoRecord!, at: 0)
                            } else {
                                // check if it is same conversation and swap it
                                var convoIndex = 0
                                for _ in homeConvos {
                                    convoIndex = convoIndex + 1
                                    let homeConversation = homeConvos[convoIndex - 1]
                                    if homeConversation.users == conversation.users {
                                        destinationVC.myConversations?[convoIndex - 1].lastMessage = conversation.lastMessage
                                        destinationVC.myConversations?.remove(at: convoIndex - 1)
                                        destinationVC.myConversations?.insert(conversation, at: 0)
                                    }
                                }
                            }
                        } else {
                            destinationVC.myConversations = [conversation]
                            destinationVC.convoRecords = [convoRecord!]
                        }
                    
                } else {
                    if newConvo {
                        if homeConvos.count > 0 {
                            destinationVC.myConversations!.insert(conversation, at:0)
                            destinationVC.convoRecords!.insert(convoRecord!, at:0)
                            
                        } else {
                            destinationVC.myConversations = [conversation]
                            destinationVC.convoRecords = [convoRecord!]
                        }
                    }
                }
                destinationVC.tableView.reloadData()
            }
        } else if unwindSegue.identifier == "groupUnwind" {
            let destinationVC = unwindSegue.destination as! CreateGroupViewController
            let homeVC = destinationVC.presentedViewController?.presentedViewController as!HomeViewController
            if (homeVC.myConversations?.count)! > 0 {
                    homeVC.myConversations?.insert(conversation!, at: 0)
                    homeVC.convoRecords?.insert(convoRecord!, at:0)
            } else {
                    homeVC.myConversations = [conversation!]
                    homeVC.convoRecords = [convoRecord!]
            }
            destinationVC.dismiss(animated: false, completion: nil)
            homeVC.tableView.reloadData()
        }
    }
 
}

class TableView: UITableView {
    
    func reloadData(_ conversation:Conversation?) {
        super.reloadData()
        if let conversation = conversation {
            if conversation.theMessages.count >= 1 {
                let index = IndexPath(row: conversation.theMessages.count - 1, section: 0)
                scrollToRow(at: index, at: .none, animated: true)
            }
        }
    }
}




