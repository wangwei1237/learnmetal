//
//  TableViewController.swift
//  MetalTest
//
//  Created by wangwei on 2018/10/11.
//  Copyright © 2018 wangwei. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    var tasks:[TaskModel]! = [TaskModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initTasks()
        
        self.title = "Metal学习任务"
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // set the dataSource&delegate
        tableView.dataSource = self
        tableView.delegate   = self
        
        let backItem: UIBarButtonItem = UIBarButtonItem()
        backItem.title = ""
        self.navigationItem.backBarButtonItem = backItem
        
        // 注册newsCell
        self.tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "TaskTableViewCell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tasks.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskTableViewCell", for: indexPath)
        
        // Configure the cell...
        //cell.backgroundColor = UIColor.blue
        cell.textLabel?.text = tasks[indexPath.row].name
        
        return cell
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tm = self.tasks[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        
        let clsName = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String
        let vcl = NSClassFromString(clsName! + "." + tm.className) as! UIViewController.Type
        let vc = vcl.init()
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func initTasks() {
        var task: TaskModel?
        
        let taskDict: [String:String] = [
            "渲染三角形": "TriangleViewController",
            "彩色三角形": "ColorTriangleViewController",
            "渲染立方体": "CubeViewController",
            "计算着色器": "CSViewController",
            "渲染动图": "ComputerPictureController",
            "光照渲染": "LightController",
            "采集摄像头": "CameraViewController",
            "采集摄像头2": "CameraMPSViewController",
            "摄像头计算管道" : "CameraCSViewController",
        ]
        
        let taskArray: [String] = [
            "渲染三角形",
            "彩色三角形",
            "渲染立方体",
            "计算着色器",
            "渲染动图",
            "光照渲染",
            "采集摄像头",
            "采集摄像头2",
            "摄像头计算管道",
        ]
        
        for item in taskArray {
            task = TaskModel(item, taskDict[item]!)
            self.tasks.append(task!)
        }
    }
}
