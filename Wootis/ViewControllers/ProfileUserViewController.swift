//
//  ProfileUserViewController.swift
//  Wootis
//
//  Created by Alex Lopez on 31/5/18.
//  Copyright © 2018 Wootis.inc. All rights reserved.
//

import UIKit

class ProfileUserViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var user: Users!
    var posts: [Post] = []
    var userId = ""
    var delegate : HeaderProfileCollectionReusableViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(userId)
        collectionView.dataSource = self
        collectionView.delegate = self
        fetchUser()
        fetchMyPosts()
    }
    
    func fetchUser() {
        Api.User.observeUsers(withId: userId) { (user) in
            self.isFollowing(userId: user.id!, completed: { (value) in
                user.isFollowing = value
                self.user = user
                self.navigationItem.title = user.username
                self.collectionView.reloadData()
            })
        }
    }
    
    func isFollowing(userId: String, completed: @escaping (Bool) -> Void) {
        Api.Follow.isFollowing(userId: userId, completed: completed)
    }
    
    func fetchMyPosts() {
        Api.MyPost.fetchMyPosts(userId: userId) { (key) in
            Api.Post.observePost(with: key, completion: { postData in
                self.posts.append(postData)
                self.collectionView.reloadData()
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ProfileUser_DetailSegue" {
            let detailpostViewController = segue.destination as! DetailPostViewController
            let postId = sender as! String
            detailpostViewController.postId = postId
        }
    }
}

extension ProfileUserViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        let post = posts[indexPath.row]
        cell.post = post
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerViewCell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "HeaderProfileCollectionReusableView", for: indexPath) as! HeaderProfileCollectionReusableView
        if let user = self.user {
            headerViewCell.user = user
            headerViewCell.delegate = self.delegate
            headerViewCell.delegate2 = self
        }
        return headerViewCell
    }
}

extension ProfileUserViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 3 - 1, height: collectionView.frame.size.width / 3 - 1)
    }
}

extension ProfileUserViewController: HeaderProfileCollectionReusableViewDelegateSwitchViewController {
    func goToSettingViewController() {
        performSegue(withIdentifier: "ProfileUser_SettingSegue", sender: nil)
    }
}

extension ProfileUserViewController: PhotoCollectionViewCellDelegate {
    func goToDetailPostViewController(postId: String) {
        performSegue(withIdentifier: "ProfileUser_DetailSegue", sender: postId)
    }
}
