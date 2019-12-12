//
//  StartViewController.swift
//  TextRecognizer
//
//  Created by aadhar on 12/12/19.
//  Copyright © 2019 Atechnos. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {

    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var lblCode: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
         print("Constant Val : \(ConstantVar.resultTxt)")
        lblCode.text = ConstantVar.resultTxt
    }
    
    @IBAction func btnStarttap(_ sender: Any) {
        let controller = storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
