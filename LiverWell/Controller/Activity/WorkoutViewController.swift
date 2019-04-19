//
//  WorkoutViewController.swift
//  LiverWell
//
//  Created by 徐若芸 on 2019/4/11.
//  Copyright © 2019 Jo Hsu. All rights reserved.
//

import UIKit
import AVFoundation

// swiftlint:disable identifier_name
class WorkoutViewController: UIViewController, UICollectionViewDelegate {
    
    var audioPlayer = AVAudioPlayer()
    
    @IBOutlet weak var workoutTitleLabel: UILabel!
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var repeatLabel: UILabel!
    
    @IBOutlet weak var repeatCollectionView: UICollectionView!
    
    @IBOutlet weak var barProgressView: UIProgressView!
    
    @IBOutlet weak var workoutImageView: UIImageView!
    
    @IBOutlet weak var soundBtn: UIButton!
    
    var barTimer: Timer?
    
    var repeatTimer: Timer?
    
    var startTime = 0
    
    var counter = 1
    
    var workoutArray: [WorkoutSet]?
    
    var workoutIndex = 0
    
    var repeatCountingText = [String]()
    
    var currentRepeat = 1
    
    var workoutMinutes: Float?
    
    var currentTIme: Float = 0.0
    
    var soundIsOn: Bool = true // offIcon -> selected
    
    @IBAction func toggleSonudBtnPressed(_ sender: UIButton) {
        
        if soundIsOn == true {
            
            audioPlayer.volume = 0
            
            soundBtn.isSelected = false // onIcon -> default
            
        } else {
            
            audioPlayer.volume = 1
            
            soundBtn.isSelected = true
            
        }
        
        soundIsOn = !soundIsOn
        
    }
    
    private func setupAudioPlayer() {
        
        let sound = Bundle.main.path(forResource: "Mermaid", ofType: "mp3")
        
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
        } catch {
            print(error)
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        
        setupAudioPlayer()
//        audioPlayer.play()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        changeTitleAndRepeatText()
        
        updateBarProgress()
        
//        barProgressView.setProgress(currentTIme, animated: false)
        
        setupGif()
        
//        audioPlayer.play()
        
    }
    
    private func setupGif() {
        
        guard let workoutArray = workoutArray else { return }
        let currentWorkout = workoutArray[workoutIndex]
        workoutImageView.animationImages = [
            UIImage(named: currentWorkout.images[0]),
            UIImage(named: currentWorkout.images[1])
            ] as? [UIImage]
        
        workoutImageView.animationDuration = currentWorkout.perDuration
        workoutImageView.startAnimating()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        repeatTimer?.invalidate()
        barTimer?.invalidate()
        repeatCountingText = [String]()
        audioPlayer.pause()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let workoutMinutes = workoutMinutes else { return }
        let maxTime = workoutMinutes * 60.0
        if let destination = segue.destination as? RestViewController {
            destination.currentTime = self.currentTIme
            destination.maxTime = maxTime
        }
        
        if let pauseVC = segue.destination as? PauseViewController {
            pauseVC.currentTime = self.currentTIme
            pauseVC.maxTime = maxTime
            pauseVC.workoutArray = workoutArray
            pauseVC.workoutIndex = workoutIndex
        }
    }
    
    private func changeTitleAndRepeatText() {
        
        guard let workoutArray = workoutArray else { return }
        
        let currentWorkout = workoutArray[workoutIndex]
        
        workoutTitleLabel.text = currentWorkout.title
        infoLabel.text = currentWorkout.hint
        
        counter = 1
        repeatLabel.text = "\(self.counter)/\(currentWorkout.count)次"
        
        changeRepeatCounts(totalCount: currentWorkout.count, timeInterval: currentWorkout.perDuration)
        
        repeatCollectionView.reloadData()
        
    }
    
    private func changeRepeatCounts(totalCount: Int, timeInterval: TimeInterval) {
        
        for i in 1...totalCount {
            let repeatCount = "\(i)/\(totalCount)次"
            repeatCountingText.append(repeatCount)
        }
        
        repeatTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { (_) in
            
            if self.counter < totalCount {
                self.repeatLabel.text = self.repeatCountingText[self.counter]
                self.counter += 1
            } else {
                self.repeatTimer?.invalidate()
                self.barTimer?.invalidate()
                self.moveToNextVC()
                
                // Repeat within current workout
                guard let workoutArray = self.workoutArray else { return }
                
                if self.currentRepeat < workoutArray[self.workoutIndex].workoutSetRepeat {
                    self.currentRepeat += 1
                    self.changeTitleAndRepeatText()
                    self.updateBarProgress()
                    
                } else {
                    // Finish repo in current workout, ready for next
                    self.workoutIndex += 1
                    self.currentRepeat = 1
                
                }
            }
        })
    }
    
    private func updateBarProgress() {
        
        guard let workoutMinutes = workoutMinutes else { return }
        let maxTime = workoutMinutes * 60.0
        
        currentTIme += 1.0
        barProgressView.progress = self.currentTIme/maxTime
        
        barTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
            if self.currentTIme < maxTime {
                self.currentTIme += 1.0
                self.barProgressView.progress = self.currentTIme/maxTime
            } else {
                return
            }
        })
    }
    
    private func moveToNextVC() {
        
        guard let workoutArray = workoutArray else { return }
        
        if currentRepeat == workoutArray[workoutIndex].workoutSetRepeat && workoutIndex == (workoutArray.count - 1) {
            performSegue(withIdentifier: "finishWorkout", sender: self)
        } else if currentRepeat == workoutArray[workoutIndex].workoutSetRepeat {
            performSegue(withIdentifier: "startRest", sender: self)
        } else {
            return
        }
        
    }
    
}

extension WorkoutViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let workoutArray = workoutArray else { return 0 }
        
        return workoutArray[workoutIndex].workoutSetRepeat
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
        let cell = repeatCollectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: RepeatCollectionViewCell.self),
            for: indexPath
        )
        
        guard let repeatCell = cell as? RepeatCollectionViewCell else { return cell }
        
        var bgColorArray = [UIColor?]()
        var textColorArray = [UIColor?]()
        guard let workoutArray = workoutArray else { return cell }
        
        for _ in 0..<workoutArray[workoutIndex].workoutSetRepeat {
            let defaultViewColor = UIColor.B5
            bgColorArray.append(defaultViewColor)
            
            let defaultTextColor = UIColor.B1
            textColorArray.append(defaultTextColor)
        }
        
        for i in 0..<currentRepeat {
            let finishedViewColor = UIColor.G2
            bgColorArray[i] = finishedViewColor
            
            let finishedTextColor = UIColor.white
            textColorArray[i] = finishedTextColor
        }
        
        repeatCell.counterLabel.text = String(indexPath.item + 1)
        repeatCell.counterLabel.textColor = textColorArray[indexPath.item]
        repeatCell.cellBackground.backgroundColor = bgColorArray[indexPath.item]
        
        return repeatCell
    }
    
}

extension WorkoutViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
        ) -> CGSize {
        guard let workoutArray = workoutArray else { return CGSize() }
        let collectionViewWidth = repeatCollectionView.bounds.width
        let cellSpace = Int(collectionViewWidth) / workoutArray[workoutIndex].workoutSetRepeat
        return CGSize(width: cellSpace, height: 25)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
        ) -> CGFloat {
        return 0
    }
    
}
