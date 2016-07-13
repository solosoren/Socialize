//
//  InitialLoadingView.swift
//  Chat
//
//  Created by Soren Nelson on 7/5/16.
//  Copyright © 2016 SORN. All rights reserved.
//

import UIKit
import CloudKit


class InitialLoadingView: UIViewController {
    
//    TODO: clean up self's
//          fix all else errors
//          fix nav bar bottom line
//          Need to subscribe to friend requests
//          Need to subscribe to conversation
//          time for messages
//          messaging image on cell
//          check out if add contact vc photos work with a bunch of contacts
//          check if accept request adds friend to tableview
//          skip login
//          logout
//          leave convo
//          see who's in the convo
    //         info button type thing?
//          create group add button switch
    //         maybe switch to checkmark once selected
    //         deselection
//          create group save button tapped segue to messaging view
    
    var friends: [Relationship] = []
    var requests: [Relationship] = []
    var conversations: [Conversation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setInitialNavBar()
        //        self.performSegueWithIdentifier("loginSegue", sender: self)
        
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        indicator.center = view.center
        view.addSubview(indicator)
        indicator.startAnimating()
                
        UserController.sharedInstance.checkForUser { (success) in
            if success {
                NSLog("SSSSSSSSSSSSS: 1")
                if let me = UserController.sharedInstance.currentUser {
                    UserController.sharedInstance.queryForMyRelationship(me, completion: { (success, relationshipRecord) in
                        if success {
                            NSLog("SSSSSSSSSSSSS: 2")
                            if let relationshipRecord = relationshipRecord {
                                UserController.sharedInstance.myRelationshipRecord = relationshipRecord
                                let myRelationship = Relationship(fullName: relationshipRecord["FullName"] as! String, userID: relationshipRecord["UserIDRef"] as! CKReference, requests: relationshipRecord["FriendRequests"] as? [CKReference], friends: relationshipRecord["Friends"] as? [CKReference], profilePic: relationshipRecord["ImageKey"] as? CKAsset)
                                UserController.sharedInstance.myRelationship = myRelationship
                                self.initiallyGrabRequests(myRelationship, completion: { (success) in
                                    if success {
                                        NSLog("SSSSSSSSSSSSS: 3")
                                        self.initiallyGrabFriends(myRelationship, completion: { (success) in
                                            if success {
                                                NSLog("SSSSSSSSSSSSS: 4")
                                                self.initiallyGrabConvos({ (success) in
                                                    if success {
                                                        print("Convos: \(self.conversations)")
                                                        dispatch_async(dispatch_get_main_queue(), {
                                                            indicator.stopAnimating()
                                                            self.performSegueWithIdentifier("initialLoad", sender: self)
                                                        })
                                                    } else {
                                                        NSLog("Couldn't grab initial conversations")
                                                    }
                                                })
                                            } else {
                                                NSLog("SSSSSSSSSSSSS: 5")
                                            }
                                        })
                                    } else {
                                        NSLog("SSSSSSSSSSSSS: 6")
                                    }
                                })
                                } else {
                                dispatch_async(dispatch_get_main_queue(), {
                                    indicator.stopAnimating()
                                    self.performSegueWithIdentifier("loginSegue", sender: self)
                                })
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue(), {
                                indicator.stopAnimating()
                                self.performSegueWithIdentifier("loginSegue", sender: self)
                            })
                        }
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        indicator.stopAnimating()
                        self.performSegueWithIdentifier("loginSegue", sender: self)
                    })
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    indicator.stopAnimating()
                    self.performSegueWithIdentifier("loginSegue", sender: self)
                })
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "initialLoad" {
            let destinationVC = segue.destinationViewController as! HomeViewController
            destinationVC.myRequests = self.requests
            destinationVC.myFriends = self.friends
            destinationVC.myConversations = self.conversations
        }
    }
    
    func initiallyGrabRequests(relationship:Relationship, completion:(success: Bool) -> Void) {
        
        if relationship.requests == nil {
            self.requests = []
            completion(success: true)
        } else if relationship.requests! != [] {
            NSLog("SSSSSSSSSSSSS: 7")
            for request in relationship.requests! {
                UserController.sharedInstance.queryForRelationshipbyUID(request.recordID) { (success, relationshipRecord) in
                    if let relationshipRecord = relationshipRecord {
                        NSLog("SSSSSSSSSSSSS: 8")
                        let requestRelationship = Relationship(fullName: relationshipRecord["FullName"] as! String, userID: relationshipRecord["UserIDRef"] as! CKReference, requests: nil, friends: nil, profilePic: relationshipRecord["ImageKey"] as? CKAsset)
                        self.requests += [requestRelationship]
                        if request == relationship.requests!.last {
                            NSLog("SSSSSSSSSSSSS: 9")
                            completion(success: true)
                        }
                    } else {
                        self.requests = []
                        if request == relationship.requests!.last {
                            completion(success: true)
                        }
                    }
                }
            }
        } else {
            self.requests = []
            completion(success: true)
        }
    }
    
    func initiallyGrabFriends(relationship:Relationship, completion:(success: Bool) -> Void) {
        
        if relationship.friends == nil {
            self.friends = []
            completion(success: true)
        } else if relationship.friends! != [] {
            NSLog("SSSSSSSSSSSSS: 10")
            for friend in relationship.friends! {
                UserController.sharedInstance.queryForRelationshipbyUID(friend.recordID, completion: { (success, relationshipRecord) in
                    if success {
                        NSLog("SSSSSSSSSSSSS: 11")
                        let friendRelationship = Relationship(fullName: relationshipRecord!["FullName"] as! String, userID: relationshipRecord!["UserIDRef"] as! CKReference, requests: nil, friends: nil, profilePic: relationshipRecord!["ImageKey"] as? CKAsset)
                        self.friends += [friendRelationship]
                        if friend == relationship.friends?.last {
                            completion(success: true)
                        }
                    } else {
                        self.friends = []
                        if friend == relationship.friends?.last {
                            completion(success: true)
                            NSLog("SSSSSSSSSSSSS: 13")

                        }
                    }
                })
            }
        } else {
            self.friends = []
            completion(success: true)
            NSLog("SSSSSSSSSSSSS: 14")
        }
    }
    
    func initiallyGrabConvos(completion:(success: Bool) -> Void) {
        ConversationController().grabUserConversations(UserController.sharedInstance.myRelationship!) { (success, conversations) in
            if success {
                self.conversations = conversations!
                completion(success: true)
            } else {
                self.conversations = []
                completion(success: false)
            }
        }
    }


}