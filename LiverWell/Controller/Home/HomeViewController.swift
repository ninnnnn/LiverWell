//
//  HomeViewController.swift
//  LiverWell
//
//  Created by 徐若芸 on 2019/4/3.
//  Copyright © 2019 Jo Hsu. All rights reserved.
//

import UIKit
import MBCircularProgressBar
import Firebase
import SCLAlertView

class HomeViewController: LWBaseViewController, UICollectionViewDelegate {
    
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
    
    let now = Date()
    
    var todayDate = ""
    
    var tempTrainWorkoutTime = 0
    
    var todayTrainTime: Int?
    
    var tempStretchWorkoutTime = 0
    
    var todayStretchTime: Int?
    
    var monSum = 0
    var tueSum = 0
    var wedSum = 0
    var thuSum = 0
    var friSum = 0
    var satSum = 0
    var sunSum = 0
    
    var dailyValue: [Int] {
        return [monSum, tueSum, wedSum, thuSum, friSum, satSum, sunSum]
    }

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
        
        getThisWeekProgress()
        
        determineStatus(
            workStartHours: 9,
            workEndHours: 18
        )
        
        groupNofity()
    }

    private func groupNofity() {
        dispatchGroup.notify(queue: .main) {
            self.showTodayWorkoutProgress()
            self.workoutCollectionView.reloadData()
            self.setupView()
            self.shareBtn.isEnabled = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        todayTrainTime = nil
        tempStretchWorkoutTime = 0
        
        todayStretchTime = nil
        tempTrainWorkoutTime = 0
        
        monSum = 0
        tueSum = 0
        wedSum = 0
        thuSum = 0
        friSum = 0
        satSum = 0
        sunSum = 0
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let stretchWorkoutTime = todayStretchTime, let trainWorkoutTime = todayTrainTime else { return }
        
        let totalWorkoutTime = stretchWorkoutTime + trainWorkoutTime
        
        if let desVC = segue.destination as? ShareViewController {
            desVC.dailyValue = dailyValue
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
    
    private func determineStatus(
        workStartHours: Int,
        workEndHours: Int
        ) {
        
        let sunday = now.dayOf(.sunday)
        let saturday = now.dayOf(.saturday)
        
        let workStart = now.dateAt(hours: workStartHours, minutes: 0)
        let workEnd = now.dateAt(hours: workEndHours, minutes: 0)
        let sleepStart = now.dateAt(hours: 21, minutes: 30)
        let sleepEnd = now.dateAt(hours: 5, minutes: 0)
        let nowHour = Calendar.current.component(.hour, from: now)
        
        if now >= saturday && now <= Calendar.current.date(byAdding: .day, value: 1, to: sunday)! {
            // weekend
            statusRemainTimeLabel.text = "休息日好好放鬆，起身動一動！"
            
            if now >= sleepEnd && now <= sleepStart {
                setupStatusAs(.resting)
            } else {
                setupStatusAs(.beforeSleep)
            }
            
        } else {
            // workday
            let fromRestHour = workEndHours - nowHour
//            let fromSleepHour = sleepStartHours - nowHour
            
            if now >= workStart && now <= workEnd {
                setupStatusAs(.working)
                statusRemainTimeLabel.text = "離休息時間還有 \(fromRestHour) 小時"
            } else if now >= workEnd && now <= sleepStart {
                setupStatusAs(.resting)
                statusRemainTimeLabel.text = "離工作時間還有 \((24 - nowHour) + workStartHours) 小時"
            } else if now >= sleepEnd && now <= workStart {
                setupStatusAs(.resting)
                statusRemainTimeLabel.text = "離工作時間還有 \(workStartHours - nowHour) 小時"
            } else {
                setupStatusAs(.beforeSleep)
                if nowHour > workEndHours {
                    statusRemainTimeLabel.text = "離工作時間還有 \((24 - nowHour) + workStartHours) 小時"
                } else if nowHour < workStartHours {
                    statusRemainTimeLabel.text = "離工作時間還有 \(workStartHours - nowHour) 小時"
                }
                
            }
            
        }
        
    }
    
    private func showToday() {
        
        let chineseMonthDate = DateFormatter.chineseMonthDate(date: now)
        let chineseDay = DateFormatter.chineseWeekday(date: now)
        
        timeLabel.text = "\(chineseMonthDate) \(chineseDay)"
        todayDate = "\(chineseMonthDate) \(chineseDay)"
        
    }
    
    private func setupStatusAs(_ homeStatus: HomeStatus) {
        
        dispatchGroup.enter()
        homeObjectManager.getHomeObject(homeStatus: homeStatus) { [weak self] (homeObject, _ ) in
            self?.homeObject = homeObject
            self?.dispatchGroup.leave()
        }
        
    }
    
    private func getThisWeekProgress() {
        
        dispatchGroup.enter()
        
        let userDefaults = UserDefaults.standard
        
        guard let uid = userDefaults.value(forKey: "uid") as? String else { return }

        let today = now

        let workoutRef = AppDelegate.db.collection("users").document(uid).collection("workout")

        workoutRef
            .whereField("created_time", isGreaterThan: today.dayOf(.monday))
            .order(by: "created_time", descending: false)
            .getDocuments { [weak self] (snapshot, error) in

            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in snapshot!.documents {

                    guard let workoutTime = document.get("workout_time") as? Int else { return }
                    guard let createdTime = document.get("created_time") as? Timestamp else { return }
                    guard let activityType = document.get("activity_type") as? String else { return }

                    let date = createdTime.dateValue()
                    
                    self?.sortBy(day: date, workoutType: activityType, workoutTime: workoutTime)

                }
                self?.dispatchGroup.leave()
            }

            self?.todayTrainTime = self?.tempTrainWorkoutTime

            self?.todayStretchTime = self?.tempStretchWorkoutTime

        }

    }
    
    private func showTodayWorkoutProgress() {
        
        guard let stretchWorkoutTime = todayStretchTime, let trainWorkoutTime = todayTrainTime else { return }
        
        let totalWorkoutTime = stretchWorkoutTime + trainWorkoutTime
        
        todayWorkoutTimeLabel.text = "\(totalWorkoutTime)"
        
        if totalWorkoutTime >= 15 {
            
            UIView.animate(withDuration: 0.5) {
                
                self.stretchProgressView.value = 15
                self.trainProgressView.value = CGFloat(integerLiteral: trainWorkoutTime * 15 / totalWorkoutTime)
                
            }
            
            stillRemainLabel.text = "太棒了"
            remainingTimeLabel.text = "達成目標"
            
        } else {
        
            UIView.animate(withDuration: 0.5) {
                
                self.stretchProgressView.value = CGFloat(totalWorkoutTime)
                self.trainProgressView.value = CGFloat(integerLiteral: trainWorkoutTime)
                
            }
            
            stillRemainLabel.text = "還剩"
            remainingTimeLabel.text = "\(15 - totalWorkoutTime)分鐘"
            
        }
        
        weekProgressCollectionView.reloadData()
        
    }
    
    private func sortBy(day date: Date, workoutType: String, workoutTime: Int) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let convertedDate = dateFormatter.string(from: date)
        
        let today = now
        
        if convertedDate == dateFormatter.string(from: today) && workoutType == "train" {
            self.tempTrainWorkoutTime += workoutTime
        } else if convertedDate == dateFormatter.string(from: today) && workoutType == "stretch" {
            self.tempStretchWorkoutTime += workoutTime
        }
        
        if convertedDate == dateFormatter.string(from: today.dayOf(.monday)) {
            self.monSum += workoutTime
        }
        
        if convertedDate == dateFormatter.string(from: today.dayOf(.tuesday)) {
            self.tueSum += workoutTime
        }
        
        if convertedDate == dateFormatter.string(from: today.dayOf(.wednesday)) {
            self.wedSum += workoutTime
        }
        
        if convertedDate == dateFormatter.string(from: today.dayOf(.thursday)) {
            self.thuSum += workoutTime
        }
        
        if convertedDate == dateFormatter.string(from: today.dayOf(.friday)) {
            self.friSum += workoutTime
        }
        
        if convertedDate == dateFormatter.string(from: today.dayOf(.saturday)) {
            self.satSum += workoutTime
        }
        
        if convertedDate == dateFormatter.string(from: today.dayOf(.sunday)) {
            self.sunSum += workoutTime
        }
        
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
            progressCell.layoutView(value: self.dailyValue[indexPath.item])

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
