//
//  ProfileViewController.swift
//  LiverWell
//
//  Created by 徐若芸 on 2019/4/8.
//  Copyright © 2019 Jo Hsu. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var indicatorView: UIView!
    @IBOutlet weak var indicatorLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusContainerView: UIView!
    @IBOutlet weak var weightContainerView: UIView!
    
    @IBOutlet var orderBtns: [UIButton]!
    
    var containerViews: [UIView] {
        
        return [statusContainerView, weightContainerView]
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.delegate = self
    }
    
    @IBAction func changePagePressed(_ sender: UIButton) {
        
        for btn in orderBtns {
            
            btn.isSelected = false
            
        }
        
        sender.isSelected = true
        
        moveIndicatorView(toPage: sender.tag)
        
    }
    
    private func moveIndicatorView(toPage: Int) {
        
        let screenWidth  = UIScreen.main.bounds.width
        
        indicatorLeadingConstraint.constant = CGFloat(toPage) * screenWidth / 2
        
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            
            self?.scrollView.contentOffset.x = CGFloat(toPage) * screenWidth
            
            self?.view.layoutIfNeeded()
            
        })
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let screenWidth  = UIScreen.main.bounds.width
        
        indicatorLeadingConstraint.constant = scrollView.contentOffset.x / 2
        
        let temp = Double(scrollView.contentOffset.x / screenWidth)
        
        let number = lround(temp)
        
        for btn in orderBtns {
            
            btn.isSelected = false
            
        }
        
        orderBtns[number].isSelected = true
        
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            
            self?.view.layoutIfNeeded()
            
        })
        
    }
    



}
