//
//  LoginViewController.swift
//  Get My Location
//
//  Created by Blake Clough on 10/5/16.
//  Copyright © 2016 Blake Clough. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    let buttonColor = UIColor(red: (226/255), green: (89/255), blue: (40/255), alpha: 1.0)

    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var aboutTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        goButton.layer.borderColor = buttonColor.cgColor
        goButton.layer.borderWidth = 2
        goButton.layer.cornerRadius = 5
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoLocation" {
            let destination = segue.destination as! LocationViewController
            destination.username = usernameTextField.text!
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func dismissKeyboard() {
        usernameTextField.resignFirstResponder()
    }
}
