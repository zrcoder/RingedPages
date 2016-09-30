//
//  ViewController.swift
//  RingedPages
//
//  Created by admin on 16/9/28.
//  Copyright © 2016年 Ding. All rights reserved.
//

import UIKit

class ViewController: UIViewController, RingedPagesDataSource, RingedPagesDelegate {
    
    lazy var pages: RingedPages = {
        let screenWidth = UIScreen.main.bounds.size.width
        let pagesFrame = CGRect(x: 0, y: 100, width: screenWidth, height: screenWidth * 0.4)
        let pages = RingedPages(frame: pagesFrame)
        let height = pagesFrame.size.height - pages.pageControlMarginBottom - pages.pageControlMarginTop - pages.pageControlHeight
        pages.carousel.mainPageSize = CGSize(width: height * 0.8, height: height)
        pages.carousel.pageScale = 0.6
        pages.dataSource = self
        pages.delegate = self
        return pages
    }()
    
    lazy var dataSource: [String] = {
        var array = [String]()
        let s = "ABCDEFG"
        for i in 0..<s.characters.count {
            array.append(String(s[i]))
        }
        return array
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(pages)
        pages.reloadData()
    }
    func numberOfItems(in ringedPages: RingedPages) -> Int {
        return dataSource.count
    }
    func ringedPages(_ pages: RingedPages, viewForItemAt index: Int) -> UIView {
        var label: UILabel?
        if let view = pages.dequeueReusablePage() {
            if view is UILabel {
                label = view as? UILabel
            }
        }
        if label == nil {
            label = UILabel()
            label?.font = UIFont.systemFont(ofSize: 50)
            label?.textAlignment = .center
            label?.textColor = UIColor.white
            label?.layer.backgroundColor = UIColor.black.cgColor
            label?.layer.cornerRadius = 5
        }
        label?.text = dataSource[index]
        return label!
    }
    
    func didSelectedCurrentPage(in pages: RingedPages) {
        print("pages selected, the current index is \(pages.currentIndex)")
    }
    func didScrolled(to index: Int, in pages: RingedPages) {
        print("Did scrolled to index: \(index)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func changeMainPageSize(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1:
            pages.carousel.mainPageSize = CGSize(width: 60, height: 100)
        case 2:
            pages.carousel.mainPageSize = CGSize(width: 100, height: 100)
        default:
            pages.carousel.mainPageSize = originMainPageSize
        }
        pages.reloadData()
    }
    var originMainPageSize: CGSize {
        var height = UIScreen.main.bounds.size.width * 0.4
        height -= (pages.pageControlMarginBottom + pages.pageControlMarginTop + pages.pageControlHeight)
        return CGSize(width: height * 0.8, height: height)
    }
    @IBAction func changePageScale(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1:
            pages.carousel.pageScale = 0.8
        case 2:
            pages.carousel.pageScale = 0.5
        default:
            pages.carousel.pageScale = 0.6
        }
        pages.reloadData()
    }
}

public extension String {
    public subscript(index: Int) -> Character {
        let index = characters.index(startIndex, offsetBy: index)
        return self[index]
    }
}

