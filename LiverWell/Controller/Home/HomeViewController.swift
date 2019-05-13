//
//  HomeViewController.swift
//  LiverWell
//
//  Created by 徐若芸 on 2019/4/3.
//  Copyright © 2019 Jo Hsu. All rights reserved.
//

import UIKit
import MBCircularProgressBar

class HomeViewController: LWBaseViewController, UICollectionViewDelegate {
    
    let homeManager = HomeManager()
    
    let homeObjectManager = HomeObjectManager()
    
    var homeObject: HomeObject?
    
    let dispatchGroup = DispatchGroup()
    
    @IBOutlet weak var suggestTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var shareBtn: UIButton!
    
    @IBOutlet weak var statusRemainTimeLabel: UILabel!
    
    @IBOutlet weak var background: UIImageView!
    
    @IBOutlet weak var trainProgressView: MBCircularProgressBarView!

    @IBOutlet weak var stretchProgressView: MBCircularProgressBarView! // 後面、加總
    
    @IBOutlet weak var todayWorkoutTimeLabel: UILabel!

    @IBOutlet weak var workoutCollectionView: UICollectionView!

    @IBOutlet weak var weekProgressCollectionView: UICollectionView!
    
    @IBOutlet weak var stillRemainLabel: UILabel!
    
    @IBOutlet weak var remainingTimeLabel: UILabel!
    
    var todayDate = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        showToday()
        
        shareBtn.isEnabled = false
        
        if UIScreen.main.nativeBounds.height == 1136 {
            statusRemainTimeLabel.isHidden = true
        } else {
//            suggestTopConstraint.constant = 20
        }
        
    }
    
    override func getData() {
        
        getThisWeekProgess()
        
        getStatus(workStartHour: 9, workEndHour: 18)
        
        groupNofity()
    }
    
    func getStatus(workStartHour: Int, workEndHour: Int) {
        
        let statusElement = homeManager.determineStatus(workStartHour: workStartHour, workEndHour: workEndHour)
        
        let status = statusElement.0
        
        let text = statusElement.1
        
        setupStatusAs(status)
        
        statusRemainTimeLabel.text = text
        
    }
    
    private func getThisWeekProgess() {
        
        dispatchGroup.enter()
        
        homeManager.getThisWeekProgress(today: Date()) { (result) in
            
            switch result {
                
            case .success(let workOuts):
                
                print(workOuts)
                
            case .failure(let error):
                
                print(error)
            }
            
            self.dispatchGroup.leave()
        }
        
    }

    private func groupNofity() {
        
        dispatchGroup.notify(queue: .main) {
            
            self.showTodayWorkoutProgress()
            
            self.setupView()
            
            self.workoutCollectionView.reloadData()
            
            self.shareBtn.isEnabled = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        homeManager.reset()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let trainWorkoutTime = homeManager.todayTrainTime
        
        let stretchWorkoutTime = homeManager.todayStretchTime
        
        let totalWorkoutTime = stretchWorkoutTime + trainWorkoutTime
        
        if let desVC = segue.destination as? ShareViewController {
            desVC.dailyValue = homeManager.dailyValue
            desVC.loadViewIfNeeded()
            desVC.todayTotalTimeLabel.text = "\(totalWorkoutTime)"
            desVC.trainTimeLabel.text = "\(trainWorkoutTime)分鐘"
            desVC.stretchTimeLabel.text = "\(stretchWorkoutTime)分鐘"
            desVC.todayDateLabel.text = todayDate
            
            if totalWorkoutTime >= 15 {
                    desVC.stretchProgressView.value = 15
                    desVC.trainProgressView.value = CGFloat(integerLiteral: trainWorkoutTime * 15 / totalWorkoutTime)
            } else {
                    desVC.stretchProgressView.value = CGFloat(totalWorkoutTime)
                    desVC.trainProgressView.value = CGFloat(integerLiteral: trainWorkoutTime)
            }
        }
    }
    
    private func showToday() {
        
        let chineseMonthDate = DateFormatter.chineseMonthDate(date: Date())
        
        let chineseDay = DateFormatter.chineseWeekday(date: Date())
        
        timeLabel.text = "\(chineseMonthDate) \(chineseDay)"
        
        todayDate = "\(chineseMonthDate) \(chineseDay)"
        
    }
    
    private func setupStatusAs(_ homeStatus: HomeStatus) {
        
        dispatchGroup.enter()
        
        homeObjectManager.getHomeObject(homeStatus: homeStatus) { [weak self] (homeObject, _ ) in
            
            self?.homeObject = homßeObject
            
            self?.dispatchGroup.leave()
        }
        
    }
    
    private func showTodayWorkoutProgress() {
        
        let todayTrainTime = homeManager.todayTrainTime
        
        let todayStretchTime = homeManager.todayStretchTime
        
        let totalWorkoutTime = todayTrainTime + todayStretchTime
        
        todayWorkoutTimeLabel.text = "\(totalWorkoutTime)"
        
        UIView.animate(withDuration: 0.5) {
            if totalWorkoutTime >= 15 {
                self.stretchProgressView.value = 15
                self.trainProgressView.value = CGFloat(integerLiteral: todayTrainTime * 15 / totalWorkoutTime)
            } else {
                self.stretchProgressView.value = CGFloat(totalWorkoutTime)
                self.trainProgressView.value = CGFloat(integerLiteral: todayTrainTime)
            }
        }
        
        if totalWorkoutTime >= 15 {
            stillRemainLabel.text = "太棒了"
            remainingTimeLabel.text = "達成目標"
        } else {
            stillRemainLabel.text = "還差"
            remainingTimeLabel.text = "\(15 - totalWorkoutTime)分鐘"
        }
        
        weekProgressCollectionView.reloadData()
        
    }
    
    private func setupView() {
        
        guard let homeObject = homeObject else { return }
        
        statusLabel.text = homeObject.title
        
        background.image = UIImage(named: homeObject.background)
        
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == workoutCollectionView {

            guard let homeObject = homeObject else { return }
            
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Activity", bundle: nil)
            
            if homeObject.status == "resting" {
                
                let desVC = mainStoryboard.instantiateViewController(withIdentifier: "TrainSetupViewController")
                guard let trainVC = desVC as? TrainSetupViewController else { return }
                trainVC.idUrl = homeObject.workoutSet[indexPath.item].id
                self.present(trainVC, animated: true)
                
            } else {
            
                let desVC = mainStoryboard.instantiateViewController(withIdentifier: "StretchSetupViewController")
                guard let stretchVC = desVC as? StretchSetupViewController else { return }
                stretchVC.idUrl = homeObject.workoutSet[indexPath.item].id
                self.present(stretchVC, animated: true)
                
            }
        }
    }
}

extension HomeViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        if collectionView == workoutCollectionView {

            guard let workoutSet = homeObject?.workoutSet else { return 0 }
            
            return workoutSet.count

        } else if collectionView == weekProgressCollectionView {

            return 7

        }

        return Int()
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView == workoutCollectionView {

            let cell = workoutCollectionView.dequeueReusableCell(
                withReuseIdentifier: String(describing: HomeCollectionViewCell.self),
                for: indexPath)

            guard let homeCell = cell as? HomeCollectionViewCell else { return cell }
            
            guard let workoutElement = homeObject?.workoutSet[indexPath.row] else { return cell }

            homeCell.layoutCell(image: workoutElement.buttonImage)

            return homeCell

        } else if collectionView == weekProgressCollectionView {

            let days = ["ㄧ", "二", "三", "四", "五", "六", "日"]

            let cell = weekProgressCollectionView.dequeueReusableCell(
                withReuseIdentifier: "WeekProgressCollectionViewCell", for: indexPath)

            guard let progressCell = cell as? WeekProgressCollectionViewCell else { return cell }

            progressCell.dayLabel.text = days[indexPath.item]
            progressCell.layoutView(value: homeManager.dailyValue[indexPath.item])

            return progressCell

        }

        return UICollectionViewCell()
    }

}

extension HomeViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        if collectionView == workoutCollectionView {

            return CGSize(width: 165, height: 119)

        } else {

            return CGSize(width: 20, height: 40)

        }

    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {

        if collectionView == weekProgressCollectionView {

            return 21

        } else {

            return 0

        }

    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {

        if collectionView == workoutCollectionView {
            
            let height = CGFloat(119) // collectionView.visibleCells[0].frame.height
            let viewHeight = collectionView.frame.size.height
            let toBottomUp = viewHeight - height

            return UIEdgeInsets(top: 0, left: 16, bottom: toBottomUp, right: 0)

        } else {

            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        }

    }

}
