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
    @IBOutlet weak var sentimentLabel: UILabel!
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        sentimentButton.layer.cornerRadius = 10
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        inputText.delegate = self
        inputText.text = "Type Here!"
        inputText.textColor = UIColor.lightGrayColor()
        sentimentProgress.angle = 0
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // MARK: Delegate Methods
    func textViewDidBeginEditing(textView: UITextView) {
        textView.text = ""
        textView.textColor = UIColor.blackColor()
    }
    // MARK: Utility Functions
    func hasText() -> Bool {
        return inputText.text.characters.count > 20
    }
   
    
    // MARK: Stop Word Function
    func readStopWords(fileName:String) -> [String] {
        let fileLocation = NSBundle.mainBundle().pathForResource(fileName, ofType: "txt")
        var readStopWords = " ";
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
    func filterStopWords(tokens:[String], stopWords: [String]) -> Set<String> {
        let tokensAfterStopWords = Set(tokens).subtract(Set(stopWords));
        return tokensAfterStopWords;
    }
    
    // MARK: Negations
    func readNegations(fileName:String) -> [String] {
        let fileLocation = NSBundle.mainBundle().pathForResource(fileName, ofType: "txt")
        var readNegations = " ";
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
      return  rawText.componentsSeparatedByCharactersInSet(NSCharacterSet (charactersInString: "-,/\"\\;?><:| "))
    }
    
    //MARK: Read Dictionary
    func readWordsFromCSUIC (fileName:String) -> [String] {
        let fileLocation = NSBundle.mainBundle().pathForResource(fileName, ofType: "txt")
        var readWords = " ";
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
        var readWords = " ";
        do {
            readWords = try String(contentsOfFile: fileLocation!, encoding: NSUTF8StringEncoding)
        }
        catch let error as NSError {
            print("Failed reading from File: \(fileLocation), Error: " + error.localizedDescription)
        }
        
        // Convert String into [String]
        let stringArray = readWords.characters.split{$0 == "\n"}.map(String.init)
        var sentimentDictionary:[String:Int] = [:]
        var i = 0;
        for string in stringArray {
            if(i != 2476) {
                let words = string.characters.split{$0 == "\t"}.map(String.init)
                sentimentDictionary[words[0]] = Int(words[1])
                i = i+1;
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
    func findSentimentScore(tokens:Set<String>,negaitveWords:[String],positiveWords:[String],negations:[String],dictionary:Dictionary<String,Int>) -> Int {
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
        return sentimentScore;
    }
    func scoreCalculator(sentimentScore:Int) -> Double {
        var normalizeScore:Double = 0.0
        if(sentimentScore < 0) {
            normalizeScore = Double(abs(sentimentScore))
        }
        else {
            normalizeScore = Double(sentimentScore)
        }
        return (normalizeScore + 10)/40
    }
    func startAnalysis(tokensAfterStopWords:Set<String>,negaitveWords:[String],positiveWords:[String],negations:[String],dictionary:Dictionary<String,Int>) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            let sentimentScore = self.findSentimentScore(tokensAfterStopWords, negaitveWords:negaitveWords, positiveWords: positiveWords,negations:negations, dictionary:dictionary)
            dispatch_async(dispatch_get_main_queue()) {
                self.stopIndicator()
                let normalizeScore = self.scoreCalculator(sentimentScore)
                self.progressLoader(normalizeScore)
            }
        }

    }
    
    //MARK: Loader
    func progressLoader(newAngle:Double) {
        sentimentProgress.animateToAngle(360*(newAngle/4.0), duration: 2, completion: nil)
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
    //MARK: IBA Action
    @IBAction func findAspectButtonPressed(sender: AnyObject) {
        print("Find Aspects button pressed")
        if hasText() {
            showIndicator();
            let tokenize = doTokenization(inputText.text)
            let stopWords = readStopWords("Stopword-List")
            let tokensAfterStopWords = filterStopWords(tokenize, stopWords: stopWords)
            let dictionary = readDictionary()
            startAnalysis(tokensAfterStopWords, negaitveWords: dictionary.negaitveWords, positiveWords: dictionary.positiveWords, negations: dictionary.negations, dictionary: dictionary.dictionary)
            }
        else {
            let alert = UIAlertController(title: "Alert", message: "Please type atleast 25 characters to start analysis!", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (result : UIAlertAction) -> Void in
                print("OK") }
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)

        }
    }

}

