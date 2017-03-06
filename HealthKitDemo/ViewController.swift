//
//  ViewController.swift
//  HealthKitDemo
//
//  Created by Mike Baglio Jr. on 3/5/17.
//  Copyright © 2017 Emmbi Mobile LLC. All rights reserved.
//

import UIKit
import HealthKit
import DatePickerDialog
import Datez

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    @IBOutlet weak var startDate: UITextField!
    @IBOutlet weak var endDate: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var errorLabel: UILabel!
    
    var results: [HealthKitResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toggleErrorVisibility(hidden: true)
        
        let df = DateFormatter()
        df.dateFormat = "M/d/yyyy h:mm a"
        let endDateStr = df.string(from: Date())
        let startDate = Date().gregorian - 1.day
        
        let startDateStr = df.string(from: startDate.date)
        
        self.startDate.text = startDateStr
        self.endDate.text = endDateStr
        
        self.startDate.delegate = self
        self.endDate.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HealthCell", for: indexPath) as! HealthCell
        
        cell.value.text = results[indexPath.row].value
        cell.date.text = results[indexPath.row].label
        
        return cell
    }
    
    @IBAction func getHealthKitData(_ sender: Any) {
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            self.toggleErrorVisibility(hidden: false)
            self.errorLabel.text = "Health kit not available"
            
            return
            
        }
        
        let healthKitStore:HKHealthStore = HKHealthStore()
        
        // Uncomment for question 1
        //queryQuestionOneAggregateValues(healthKitStore: healthKitStore)
        
        // Uncomment for question 2
        //queryQuestionTwoDailyData(quantityType: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!, healthKitStore: healthKitStore)
        
        // Uncomment for question 3
        queryQuestionThreeIndividualSamples(quantityType: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!, healthKitStore: healthKitStore)
    }
    
    
    func queryQuestionOneAggregateValues(healthKitStore: HKHealthStore) {
        
        let healthDataToRead = Set(arrayLiteral: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!)
        
        // Request authorization to read and/or write the specific data.
        healthKitStore.requestAuthorization(toShare: nil, read: healthDataToRead) { (success, error) -> Void in
            if(error != nil) {
                self.toggleErrorVisibility(hidden: false)
                self.errorLabel.text = "Error obtaining permission"
                return
            }
        }
        
        //   Define the sample type
        let sampleType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        
        let df = DateFormatter()
        df.dateFormat = "M/d/yyyy h:mm a"
        let start = df.date(from: startDate.text!)!
        let end = df.date(from: endDate.text!)!
        
        //  Set the predicate
        let predicate = HKQuery.predicateForSamples(withStart: start,
                                                    end: end, options: [])
        
        let statisticsQuery = HKStatisticsQuery(quantityType: sampleType!,
                                                quantitySamplePredicate: predicate,
                                                options: .cumulativeSum) { query, results, error in
                                                    
                                                    DispatchQueue.main.async {
                                                        if results != nil {
                                                            let quantity = results?.sumQuantity()
                                                            let unit = HKUnit.count()
                                                            let totalSteps = quantity?.doubleValue(for: unit)
                                                            if(totalSteps != nil) {
                                                                
                                                                self.results.removeAll()
                                                                self.results.append(HealthKitResult())
                                                                self.results[0].label = String(describing: totalSteps!) + " Steps"
                                                                
                                                                self.tableView.reloadData()
                                                                self.toggleErrorVisibility(hidden: true)
                                                            } else {
                                                                self.toggleErrorVisibility(hidden: false)
                                                                self.errorLabel.text = "No Data"
                                                            }
                                                        } else {
                                                            self.toggleErrorVisibility(hidden: false)
                                                            self.errorLabel.text = "ERROR"
                                                            return
                                                        }
                                                    }
        }
        // execute the Query
        healthKitStore.execute(statisticsQuery)
    }
    
    func queryQuestionTwoDailyData(quantityType: HKQuantityType, healthKitStore: HKHealthStore) {
        
        let healthDataToRead = Set(arrayLiteral: quantityType)
        
        // Request authorization to read and/or write the specific data.
        healthKitStore.requestAuthorization(toShare: nil, read: healthDataToRead) { (success, error) -> Void in
            if(error != nil) {
                self.toggleErrorVisibility(hidden: false)
                self.errorLabel.text = "Error obtaining permission"
                return
            }
        }
        
        var interval = DateComponents()
        interval.day = 1
        
        let df = DateFormatter()
        df.dateFormat = "M/d/yyyy h:mm a"
        let start = df.date(from: startDate.text!)!
        let end = df.date(from: endDate.text!)!
        
        self.results.removeAll()
        self.tableView.reloadData()
        
        //  Set the predicate
        let predicate = HKQuery.predicateForSamples(withStart: start.gregorian.beginningOfDay.date,
                                                    end: end.gregorian.beginningOfDay.date, options: [])
        
        let statisticsQuery = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: start.gregorian.beginningOfDay.date, intervalComponents: interval)
        
        
        statisticsQuery.initialResultsHandler = {
            query, results, error in
            
            guard let statsCollection = results else {
                // Perform proper error handling here
                self.toggleErrorVisibility(hidden: false)
                self.errorLabel.text = "*** An error occurred while calculating the statistics: \(error?.localizedDescription) ***"
                return
            }
            
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                statsCollection.enumerateStatistics(from: start, to: end) { [unowned self] statistics, stop in
                    
                    if let quantity = statistics.sumQuantity() {
                        let date = statistics.startDate
                        
                        
                        let shortFormat = DateFormatter()
                        shortFormat.dateFormat = "M/d/yyyy h:mm a"
                        let label = shortFormat.string(from: date)
                        let value = quantity.doubleValue(for: HKUnit.count())
                        
                        self.toggleErrorVisibility(hidden: true)
                        self.results.append(HealthKitResult())
                        self.results.last?.value = String(describing: value)
                        self.results.last?.label = label
                        self.tableView.insertRows(at: [IndexPath(row: self.results.count - 1, section: 0)], with: .
                            automatic)
                    } else {
                        self.toggleErrorVisibility(hidden: false)
                        self.errorLabel.text = "ERROR"
                        return
                    }
                }
                
                self.tableView.endUpdates()
            }
        }
        // execute the Query
        healthKitStore.execute(statisticsQuery)
    }
    
    func queryQuestionThreeIndividualSamples(quantityType: HKQuantityType, healthKitStore: HKHealthStore) {
        
        let healthDataToRead = Set(arrayLiteral: quantityType)
        
        // Request authorization to read and/or write the specific data.
        healthKitStore.requestAuthorization(toShare: nil, read: healthDataToRead) { (success, error) -> Void in
            if(error != nil) {
                self.toggleErrorVisibility(hidden: false)
                self.errorLabel.text = "Error obtaining permission"
                return
            }
        }
        
        var interval = DateComponents()
        interval.day = 1
        
        let df = DateFormatter()
        df.dateFormat = "M/d/yyyy h:mm a"
        let start = df.date(from: startDate.text!)!
        let end = df.date(from: endDate.text!)!
        
        self.results.removeAll()
        self.tableView.reloadData()
        
        //  Set the predicate
        let predicate = HKQuery.predicateForSamples(withStart: start.gregorian.beginningOfDay.date,
                                                    end: end.gregorian.beginningOfDay.date, options: [])
        
        let sampleQuery = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
            query, results, error in
            
            
            guard let samples = results as? [HKQuantitySample] else {
                // Perform proper error handling here
                self.toggleErrorVisibility(hidden: false)
                self.errorLabel.text = "*** An error occurred while calculating the statistics: \(error?.localizedDescription) ***"
                return
            }
            
            DispatchQueue.main.async {
                
                self.tableView.beginUpdates()
                self.toggleErrorVisibility(hidden: true)
                
                for sample in samples {
                    
                    let shortFormat = DateFormatter()
                    shortFormat.dateFormat = "M/d/yyyy h:mm a"
                    let label = shortFormat.string(from: sample.startDate)
                    let value = sample.quantity.doubleValue(for: HKUnit.count())
                    
                    self.results.append(HealthKitResult())
                    self.results.last?.value = String(describing: value)
                    self.results.last?.label = label
                    self.tableView.insertRows(at: [IndexPath(row: self.results.count - 1, section: 0)], with: .
                        automatic)
                }
                
                self.tableView.endUpdates()
            }
        }
        // execute the Query
        healthKitStore.execute(sampleQuery)
    }
    
    func endDateClicked(sender: UITextField) {
        DatePickerDialog().show(title: "Select End Date", doneButtonTitle: "Done", cancelButtonTitle: "Cancel", datePickerMode: .dateAndTime) {
            (date) -> Void in
            
            if let date = date {
                let df = DateFormatter()
                df.dateFormat = "M/d/yyyy h:mm a"
                let dateStr = df.string(from: date as Date)
                
                self.endDate.text = dateStr
            }
        }
    }
    
    func toggleErrorVisibility(hidden: Bool) {
        self.errorLabel.isHidden = hidden
        self.tableView.isHidden = !hidden
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        if(textField == startDate) {
            startDateClicked(sender: textField)
        } else if(textField == endDate) {
            endDateClicked(sender: textField)
        } else {
            return true
        }
        
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
    
    func startDateClicked(sender: UITextField) {
        DatePickerDialog().show(title: "Select Start Date", doneButtonTitle: "Done", cancelButtonTitle: "Cancel", datePickerMode: .dateAndTime) {
            (date) -> Void in
            
            if let date = date {
                let df = DateFormatter()
                df.dateFormat = "M/d/yyyy h:mm a"
                let dateStr = df.string(from: date as Date)
                
                self.startDate.text = dateStr
            }
        }
    }
    
}

