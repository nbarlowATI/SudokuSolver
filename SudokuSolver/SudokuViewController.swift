//
//  SudokuViewController.swift
//  sudokuPrep5
//
//  Created by Nicholas Barlow on 03/02/2016.
//  Copyright © 2016 Nicholas Barlow. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class SudokuViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var squares : [UITextField]!
    let boldFont = UIFont(name: "System", size: 14)
    let darkGreenColor = UIColor(red: 0, green: 165/255, blue: 0, alpha: 1)
    var sudoku: SudokuObject! = SudokuObject()
    var sudokuGen: sudokuGenerator! = sudokuGenerator()
    var activityIndicator:UIActivityIndicatorView!
    var listOfInputNumbers: [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for index in 0...80 {
            squares[index].text=""
            squares[index].font = boldFont
            squares[index].delegate = self
            squares[index].keyboardType = UIKeyboardType.numberPad
            //to dismiss keyboard by tapping background
            //Looks for single or multiple taps.
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SudokuViewController.dismissKeyboard))
            view.addGestureRecognizer(tap)
        }
        
        // Do any additional setup after loading the view, typically from a nib.
        sudoku.initialize()
        /// setEasySudoku()

    }

    
    @IBAction func setSudoku() {
        for index in 0...80 {
            let inputNum = Int(squares[index].text!)
            if inputNum < 10 && inputNum > 0 {
                sudoku!.setNumber(index, number: inputNum!)
                //var setColour: UIColor?
                squares[index].font = boldFont
                squares[index].textColor = UIColor.blue
                
            } else {
                squares[index].text! = ""
            }
            
        }
        sudoku.setStartingValues()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    @IBAction func findNextNumber() {
        for index in 0...80 {
            let inputNum = Int(squares[index].text!)
            if inputNum < 10 && inputNum > 0 {
                sudoku!.setNumber(index, number: inputNum!)
            }
        }
        let nextSquare = sudoku.findNextNumber()
        squares[nextSquare.getID()].text = sudoku.getVal(nextSquare.getID())
        squares[nextSquare.getID()].textColor = darkGreenColor
    }
    

    @IBAction func solveSudoku() {
        addActivityIndicator()
        for index in 0...80 {
            let inputNum = Int(squares[index].text!)
            if inputNum < 10 && inputNum > 0 {
                sudoku!.setNumber(index, number: inputNum!)
            }
        }
        let isWrongToStartWith: Bool = sudoku.checkIfWrong()
        if (isWrongToStartWith) {
            let wrongSquares = sudoku.getWrongSquares()
            for wsquare in wrongSquares {
                let index = wsquare.getID()
                squares[index].font = boldFont
                squares[index].textColor = UIColor.red
            }
            removeActivityIndicator()
            return
        }
        
        
        print("about to call a sudoku method")
        let progress = sudoku.calculateProgress()
        print("Progress is \(progress)")
        let isSolved : Int = sudoku.solve(false)
        if isSolved > 0 {
            for index in 0...80 {
                squares[index].text = sudoku.getVal(index)
            }
            for solvedSquare in sudoku.listOfSolvedSmallSquares {
                squares[solvedSquare.getID()].textColor = darkGreenColor
            }
        } else {
            sudoku.saveSnapshot("0")
            sudoku.reset()
            print("Could not solve")
        }
        removeActivityIndicator()
    }
    
    func addActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: view.bounds)
        activityIndicator.activityIndicatorViewStyle = .gray
        activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.25)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }
    
    
    func removeActivityIndicator() {
        activityIndicator.removeFromSuperview()
        activityIndicator = nil
    }


    func setListOfNumbers(_ inputNums: [Int]) {
        self.listOfInputNumbers = inputNums
        for index in 0...80 {
            if inputNums[index] > 0 && inputNums[index] < 10 {
                squares[index].text = String(inputNums[index])
            }
        }
        self.setSudoku()
    }

    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func resetSudoku() {
        for index in 0...80 {
            squares[index].text=""
            squares[index].textColor = UIColor.black
            
        }
        
        sudoku.reset()
    }
    func fillSudoku() {
        for index in 0...80 {
            let number = sudoku.getVal(index)
            if number != "X" {
                squares[index].text=sudoku.getVal(index)
                /// squares[index].textColor = UIColor.blueColor()
            }
        }
        
        
    }
    @IBAction func generateSudoku() {
        resetSudoku()
        sudoku.reset()
        sudokuGen.initialize()
        /// var difficulty: Difficulty = .Test
        let alert = UIAlertController(title: "How difficult?",
            message: "select one of the options below",
            preferredStyle: .alert)
        let actionEasy = UIAlertAction(title: "Easy", style: .default, handler: {action in
            ///  difficulty = .Easy})
            self.sudoku = self.sudokuGen.makeSudoku(.easy)
            self.fillSudoku()
            self.setSudoku()
        })
        alert.addAction(actionEasy)
        let actionMedium = UIAlertAction(title: "Medium", style: .default, handler: {action in
            ///   difficulty = .Medium})
            self.sudoku = self.sudokuGen.makeSudoku(.medium)
            self.fillSudoku()
            self.setSudoku()
        })
        
        alert.addAction(actionMedium)
        let actionHard = UIAlertAction(title: "Hard", style: .default, handler: {action in
            ///  difficulty = .Hard})
            self.sudoku = self.sudokuGen.makeSudoku(.hard)
            self.fillSudoku()
            self.setSudoku()
        })
        alert.addAction(actionHard)
        present(alert, animated: true, completion: nil)
        
     }
    
}

extension UITextFieldDelegate {
    func textField(_ textField: UITextField,
        shouldChangeCharactersInRange range: NSRange,
        replacementString string: String) -> Bool {
            
            // Create an `NSCharacterSet` set which includes everything *but* the digits
            let inverseSet = CharacterSet(charactersIn:"0123456789").inverted
            
            // At every character in this "inverseSet" contained in the string,
            // split the string up into components which exclude the characters
            // in this inverse set
            let components = string.components(separatedBy: inverseSet)
            
            // Rejoin these components
            let filtered = components.joined(separator: "")  // use join("", components) if you are using Swift 1.2
            
            // If the original string is equal to the filtered string, i.e. if no
            // inverse characters were present to be eliminated, the input is valid
            // and the statement returns true; else it returns false
            return string == filtered
            
    }
    
}

