//
//  ViewController.swift
//  Sentiment Analyzer
//
//  Created by Muhammad Rafay on 8/30/16.
//  Copyright © 2016 Muhammad Rafay. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var inputText: UITextView!
    @IBOutlet weak var sentimentButton: UIButton!
    @IBOutlet weak var sentimentProgress: KDCircularProgress!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var sentimentLabel: UILabel!
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        //To make round edges of button
        sentimentButton.layer.cornerRadius = 10
        resetButton.layer.cornerRadius = 10
        //Dismiss Keyboard if touched anywhere on screen
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //Initializing label, progress angle and placeholder text
        inputText.delegate = self
        inputText.text = "Type Here!"
        inputText.textColor = UIColor.lightGrayColor()
        setProgress(0)
        hideSentimentLable(true)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // MARK: Delegate Methods
    func textViewDidBeginEditing(textView: UITextView) {
        if(textView.text == "Type Here!") {
            resetText()
            textView.textColor = UIColor.blackColor()
        }
    }
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }  
    // MARK: Utility Functions
    func hasText() -> Bool {
        return inputText.text.characters.count > 20
    }
    func resetText() {
        inputText.text = ""
    }
    func hideSentimentLable(flag:Bool) {
        sentimentLabel.hidden = flag
    }
    // MARK: Stop Word Function
    func readStopWords(fileName:String) -> [String] {
        let fileLocation = NSBundle.mainBundle().pathForResource(fileName, ofType: "txt")
        var readStopWords = " "
        do {
            readStopWords = try String(contentsOfFile: fileLocation!, encoding: NSUTF8StringEncoding)
        }
        catch let error as NSError {
            print("Failed reading from File: \(fileLocation), Error: " + error.localizedDescription)
        }

        // Convert String into [String]
        let words = readStopWords.characters.split{$0 == "\r\n"}.map(String.init)
        return words
    }
    func filterStopWords(tokens:[String], stopWords: [String]) -> [String] {
        var tokenizeAfterStopWords = tokens
        for word in tokens {
            if stopWords.contains(word) {
                tokenizeAfterStopWords = tokenizeAfterStopWords.filter{$0 != word}
            }
        }
        return tokenizeAfterStopWords
    }
    
    // MARK: Negations
    func readNegations(fileName:String) -> [String] {
        let fileLocation = NSBundle.mainBundle().pathForResource(fileName, ofType: "txt")
        var readNegations = " "
        do {
            readNegations = try String(contentsOfFile: fileLocation!, encoding: NSUTF8StringEncoding)
        }
        catch let error as NSError {
            print("Failed reading from File: \(fileLocation), Error: " + error.localizedDescription)
        }
        
        // Convert String into [String]
        let words = readNegations.characters.split{$0 == "\r\n"}.map(String.init)
        return words
    }


    
    // MARK: Tokenization
    func doTokenization(rawText: String) -> [String] {
      return  rawText.componentsSeparatedByCharactersInSet(NSCharacterSet (charactersInString: "-,/\"\\?><:| "))
    }
    
    //MARK: Read Dictionary
    func readWordsFromCSUIC (fileName:String) -> [String] {
        let fileLocation = NSBundle.mainBundle().pathForResource(fileName, ofType: "txt")
        var readWords = " "
        do {
            readWords = try String(contentsOfFile: fileLocation!, encoding: NSUTF8StringEncoding)
        }
        catch let error as NSError {
            print("Failed reading from File: \(fileLocation), Error: " + error.localizedDescription)
        }
        
        // Convert String into [String]
        let words = readWords.characters.split{$0 == "\n"}.map(String.init)
        return words
    }

    
    func readAFFIN(fileName:String) -> Dictionary<String,Int> {
        let fileLocation = NSBundle.mainBundle().pathForResource(fileName, ofType: "txt")
        var readWords = " "
        do {
            readWords = try String(contentsOfFile: fileLocation!, encoding: NSUTF8StringEncoding)
        }
        catch let error as NSError {
            print("Failed reading from File: \(fileLocation), Error: " + error.localizedDescription)
        }
        
        // Convert String into [String]
        let stringArray = readWords.characters.split{$0 == "\n"}.map(String.init)
        var sentimentDictionary:[String:Int] = [:]
        var i = 0
        for string in stringArray {
            if(i != 2476) {
                let words = string.characters.split{$0 == "\t"}.map(String.init)
                sentimentDictionary[words[0]] = Int(words[1])
                i = i+1
            }
        }
        return sentimentDictionary
    }
    func readDictionary() -> (negaitveWords:[String],positiveWords:[String],negations:[String],dictionary:Dictionary<String,Int>){
        let negativeWords = readWordsFromCSUIC("negative-words")
        let positiveWords = readWordsFromCSUIC("positive-words")
        let sentimetnWordsFromAFFIN = readAFFIN("AFINN-111")
        let negations = readNegations("negated-words")
        return (negativeWords,positiveWords,negations,sentimetnWordsFromAFFIN)
    }
    
    //MARK: Sentiment Analysis
    func findSentimentScore(tokens:[String],negaitveWords:[String],positiveWords:[String],negations:[String],dictionary:Dictionary<String,Int>) -> Int {
        var sentimentScore = 0
        for word in tokens {
            let result = dictionary[word]
            if negations.contains(word) {
                sentimentScore = sentimentScore - 2
            }
            if result != nil {
                sentimentScore = sentimentScore + result!
            }
            else {
                if negaitveWords.contains(word) {
                    sentimentScore = sentimentScore - 2
                }
                else if positiveWords.contains(word) {
                    sentimentScore = sentimentScore + 2
                }
            }
            
        }
        return sentimentScore
    }
    func scoreCalculator(sentimentScore:Int) -> Double {
        var normalizeScore:Double = Double(sentimentScore)

        if(sentimentScore < 0) {
            sentimentLabel.text = "Negative!"
            return (120 + (4 * Double(abs(sentimentScore))))
        }
        else if(sentimentScore > 10) {
            normalizeScore = normalizeScore - (normalizeScore - 9)
            sentimentLabel.text = "Positive!"
            return normalizeScore*13
        }
        else if (sentimentScore == 0) {
            sentimentLabel.text = "Neutral!"
            return normalizeScore
        }
        else {
            sentimentLabel.text = "Positive!"
            return normalizeScore * 13
        }
    }
    func startAnalysis(tokensAfterStopWords:[String],negaitveWords:[String],positiveWords:[String],negations:[String],dictionary:Dictionary<String,Int>) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            let sentimentScore = self.findSentimentScore(tokensAfterStopWords, negaitveWords:negaitveWords, positiveWords: positiveWords,negations:negations, dictionary:dictionary)
            dispatch_async(dispatch_get_main_queue()) {
                self.stopIndicator()
                let normalizeScore = self.scoreCalculator(sentimentScore)
                self.progressLoader(normalizeScore)
                self.hideSentimentLable(false)
            }
        }

    }
    
    //MARK: Loader
    func progressLoader(newAngle:Double) {
        sentimentProgress.animateToAngle(newAngle, duration: 1, completion: nil)
    }
    func showIndicator() {
        indicator.hidden = false
        indicator.startAnimating()
        view.alpha = 0.5
    }
    func stopIndicator() {
        indicator.hidden = true
        indicator.stopAnimating()
        view.alpha = 1
    }
    func setProgress(angle:Double) {
        sentimentProgress.angle = angle
    }
    //MARK: Alerts
    func showAlert() {
        let alert = UIAlertController(title: "Alert", message: "Please type atleast 25 characters to start analysis!", preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (result : UIAlertAction) -> Void in
            print("OK") }
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    //MARK: IBA Action
    @IBAction func findAspectButtonPressed(sender: AnyObject) {
        print("Find Aspects button pressed")
        if hasText() {
            showIndicator()
            dismissKeyboard()
            let tokenize = doTokenization(inputText.text.lowercaseString)
            let stopWords = readStopWords("Stopword-List")
            let tokensAfterStopWords = filterStopWords(tokenize, stopWords: stopWords)
            let dictionary = readDictionary()
            startAnalysis(tokensAfterStopWords, negaitveWords: dictionary.negaitveWords, positiveWords: dictionary.positiveWords, negations: dictionary.negations, dictionary: dictionary.dictionary)
            }
        else {
            showAlert()
        }
    }
    @IBAction func resetButtonPressed(sender: AnyObject) {
        print("Reset button pressed")
        setProgress(0)
        resetText()
        hideSentimentLable(true)
    }

}

