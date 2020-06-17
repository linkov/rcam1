import UIKit

class FilterListViewController: UITableViewController {

    
    var selectionDelegate: FilterSelectionDelegate?
    var isFirstFilter = false;
    var isF3 = false;
    var isF4 = false;
    var filterDisplayViewController: FilterDisplayViewController? = nil
    var objects = NSMutableArray()
    var cellId = "Cell"
    // #pragma mark - Segues

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
//        if segue.identifier == "showDetail" {
//            if let indexPath = self.tableView.indexPathForSelectedRow {
//                let filterInList = filterOperations[(indexPath as NSIndexPath).row]
//                (segue.destination as! FilterDisplayViewController).filterOperation = filterInList
//            }
//        }
//
//    }
    
    override func viewDidLoad() {
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
    }

    // #pragma mark - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     
        return filterOperations.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let filterInList:FilterOperationInterface = filterOperations[(indexPath as NSIndexPath).row]
        
        if (selectionDelegate != nil) {
            
            
            if (isFirstFilter) {
                selectionDelegate?.didSelectFilter1(filterInList)

            } else {
                
                
                if (isF3) {
                    selectionDelegate?.didSelectFilter3(filterInList)
                } else {
                    selectionDelegate?.didSelectFilter2(filterInList)
                }
                
                
            }
            
            
        }
        
        self.dismiss(animated: true, completion: nil)
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)

        let filterInList:FilterOperationInterface = filterOperations[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = filterInList.listName
        return cell
    }
}

