//
//  WorkoutManager.swift
//  LiverWell
//
//  Created by 徐若芸 on 2019/4/16.
//  Copyright © 2019 Jo Hsu. All rights reserved.
//

import Foundation

class WorkoutManager {
    
    let decoder = JSONDecoder()
    let session: URLSession
    
    init(configuration: URLSessionConfiguration) {
        self.session = URLSession(configuration: configuration)
    }
    
    convenience init() {
        self.init(configuration: .default)
    }

    func getWorkout(
        activity: ActivityItems,
        completionHandler completion: @escaping ([WorkoutElement]?, Error?
        ) -> Void) {
    
        guard let url = URL(
            string: "https://liver-well.firebaseio.com/activityVC/\(activity.url())/workout.json"
            ) else { return }
        
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { data, response, error in
            
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                
                do {
                    let workouts: [WorkoutElement] = try self.decoder.decode(
                        [WorkoutElement].self,
                        from: data)
                    
                    completion(workouts, nil)
                    
                } catch {
                    
                }
                
            }
            
        }
        
        task.resume()
        
    }
    
}
