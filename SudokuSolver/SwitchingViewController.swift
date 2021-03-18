//
//  SwitchingViewController.swift
//  sudokuPrep5
//
//  Created by Nicholas Barlow on 03/02/2016.
//  Copyright © 2016 Nicholas Barlow. All rights reserved.
//

import UIKit

class SwitchingViewController: UIViewController {
    fileprivate var sudokuViewController: SudokuViewController!
    fileprivate var photoViewController: PhotoViewController!
    ////var listOfOCRNumbers: [Int] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        sudokuViewController = storyboard?.instantiateViewController(withIdentifier: "sudoku") as! SudokuViewController
        sudokuViewController.view.frame = view.frame
        switchViewController(from: nil, to: sudokuViewController)

        // Do any additional setup after loading the view.
    }
    @IBOutlet weak var switchingBarButton: UIBarButtonItem!

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        if sudokuViewController != nil && sudokuViewController!.view.superview == nil {
            sudokuViewController = nil
        }
        if photoViewController != nil && photoViewController!.view.superview == nil {
            photoViewController = nil
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func snapSudoku(_ sender: UIBarButtonItem) {
        /// create the new view controller if required
        if photoViewController?.view.superview == nil {
            if photoViewController == nil {
                photoViewController = storyboard?.instantiateViewController(withIdentifier: "photo") as! PhotoViewController
            }
        } else if sudokuViewController?.view.superview == nil {
            if sudokuViewController == nil {
                sudokuViewController = storyboard?.instantiateViewController(withIdentifier: "photo") as! SudokuViewController
            }
        }
        // switch view controllers
        if sudokuViewController != nil && sudokuViewController!.view.superview != nil {
            photoViewController.view.frame = view.frame
            print("About to switch from sudoku view to photo view")
            self.switchingBarButton.title = "Switch to Sudoku view"
            switchViewController(from: sudokuViewController, to: photoViewController)
        } else {
            ////
            sudokuViewController.view.frame = view.frame
            self.switchingBarButton.title = "Switch to Photo view"
            var listOfOCRNumbers: [Int] = photoViewController.getListOfNumbers()
            sudokuViewController.setListOfNumbers(listOfOCRNumbers)
            switchViewController(from: photoViewController, to: sudokuViewController)
        }
        
    }
    
    fileprivate func switchViewController(from fromVC:UIViewController?,to toVC:UIViewController?) {
        if fromVC != nil {
            fromVC!.willMove(toParentViewController: nil)
            fromVC!.view.removeFromSuperview()
            fromVC!.removeFromParentViewController()
        }
        if toVC != nil {
            self.addChildViewController(toVC!)
            self.view.insertSubview(toVC!.view, at: 0)
            toVC!.didMove(toParentViewController: self)
        }

    }

}
