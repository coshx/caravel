import UIKit

class MainController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onTypeChange(sender: AnyObject) {
        let control = sender as! UISegmentedControl
        BaseController.isUsingWKWebView = control.selectedSegmentIndex == 1
    }
    
    @IBAction func unwind(sender: UIStoryboardSegue) {
        
    }
}

