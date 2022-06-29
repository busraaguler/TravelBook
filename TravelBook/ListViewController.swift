//
//  ListViewController.swift
//  TravelBook
//
//  Created by busraguler on 13.06.2022.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    

    @IBOutlet weak var tableView: UITableView!
    var titleArray = [String]()
    var idArray = [UUID]()
    var chosenTitle = ""
    var chosenTitleId : UUID?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        tableView.delegate = self
        tableView.dataSource = self
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("New Place"), object: nil)
    }
    @objc func getData() {
        
        let appDelagate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelagate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        
        request.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(request)
            
            if results.count>0{
                
                self.titleArray.removeAll(keepingCapacity: false)
                self.idArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject]{
                    
                    if let title = result.value(forKey: "title") as? String{
                        
                        self.titleArray.append(title)
                        
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                       
                    }
                    
                   tableView.reloadData()
                }
            }
            
        }catch{
            print("error")
        }
        
        
        
    }
    
    @objc func  addButtonClicked(){
        chosenTitle = "" 
        performSegue(withIdentifier: "goToViewController", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = titleArray[indexPath.row]
        chosenTitleId = idArray[indexPath.row]
        
        performSegue(withIdentifier: "goToViewController", sender: nil)
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToViewController" {
            let destianationVC = segue.destination as! ViewController
            destianationVC.selectedTitle = chosenTitle
            destianationVC.selectedTitleId = chosenTitleId
            
        }
    }

  

}
