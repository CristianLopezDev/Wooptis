//
//  CommentViewController.swift
//  Wootis
//
//  Created by Alex Lopez on 25/5/18.
//  Copyright © 2018 Wootis.inc. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class CommentViewController: UIViewController {
    @IBOutlet weak var commentLabel: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomConstrain: NSLayoutConstraint!
    
    var postId: String!
    var comments = [Comment]()
    var users = [Users]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Comments"
        tableView.dataSource = self
        tableView.estimatedRowHeight = 77
        tableView.rowHeight = UITableViewAutomaticDimension
        empty()
        handleTextField()
        loadComments()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        UIView.animate(withDuration: 0.3) {
            self.bottomConstrain.constant = -keyboardFrame!.height
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.bottomConstrain.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func sendComment(_ sender: Any) {
        let commentsReference = Api.Comment.REF_COMMENTS
        let newCommentId = commentsReference.childByAutoId().key
        let newCommentReference = commentsReference.child(newCommentId)
        guard let currentUser = Auth.auth().currentUser?.uid else {
            return
        }
        let userId = currentUser
        newCommentReference.setValue(["userID": userId, "comment": commentLabel.text!], withCompletionBlock: { (error, ref) in
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            let postCommentRef = Api.Post_Comment.REF_POSTS_COMMENTS.child(self.postId)
            postCommentRef.setValue(true, withCompletionBlock: { (error, ref) in
                if error != nil {
                    ProgressHUD.showError(error!.localizedDescription)
                }
            })
            self.empty()
            self.view.endEditing(true)
        })
    }
    
    func loadComments() {
        Api.Post_Comment.REF_POSTS_COMMENTS.child(self.postId).observe(.childAdded, with: { snapshot in
            Api.Comment.observeComments(withPostId: snapshot.key, completion: { comment in
                print(comment)
            self.fetchUser(userId: comment.userId!, completed: {
                    self.comments.append(comment)
                    self.tableView.reloadData()
                })
            })
        })
    }
    
    func fetchUser(userId: String, completed: @escaping () -> Void) {
        Api.User.observeUsers(withId: userId, completion: { user in
            self.users.append(user)
            completed()
        })
    }
    
    func empty() {
        self.commentLabel.text = ""
        self.sendButton.isEnabled = false
        self.sendButton.setTitleColor(UIColor.lightGray, for: UIControlState.normal)
    }
    
    func handleTextField(){
        commentLabel.addTarget(self, action: #selector(SignUpViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
    }
    
    @objc func textFieldDidChange(){
        if let commentText = commentLabel.text, !commentText.isEmpty {
            sendButton.setTitleColor(UIColor.black, for: UIControlState.normal)
            sendButton.isEnabled = true
            return
        }
        sendButton.setTitleColor(UIColor.lightGray, for: UIControlState.normal)
        sendButton.isEnabled = false
    }
}

extension CommentViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentTableViewCell
        let comment = comments[indexPath.row]
        let user = users[indexPath.row]
        cell.comment = comment
        cell.user = user
        return cell
    }
}
