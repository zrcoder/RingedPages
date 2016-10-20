//
//  PagesCarousel.swift
//  RingedPages
//
//  Created by admin on 16/9/28.
//  Copyright © 2016年 Ding. All rights reserved.
//

import UIKit

public protocol PagesCarouselDataSource {
    func numberOfItems(inCarousel carousel: PagesCarousel) -> Int
    func carousel(_ carousel: PagesCarousel, pageForItemAt index: Int) -> UIView
}

@objc public protocol PagesCarouselDelegate {
    @objc optional func didScrolled(to index: Int, in carousel: PagesCarousel)
    @objc optional func didSelectedCurrentPage(in carousel: PagesCarousel)
}


open class PagesCarousel: UIView, UIScrollViewDelegate {
    open var mainPageSize = CGSize.zero
    open var pageScale: CGFloat = 1.0
    open var autoScrollInterval: TimeInterval = 5.0 // is <= 0, will not scroll automatically
    
    open var dataSource: PagesCarouselDataSource?
    open var delegate: PagesCarouselDelegate?
    
    open var currentIndex: Int {
        get {
            return p_currentIndex
        }
    }
    open func reloadData() {
        needsReload = true
        for view in scrollView.subviews {
            view.removeFromSuperview()
        }
        removeTimer()
        setNeedsLayout()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        p_setUp()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        p_setUp()
    }
    open func dequeueReusablePage() -> UIView? {
        let page = reusablePages.last
        if page != nil {
            reusablePages.removeLast()
        }
        return page
    }
    open func scroll(to index: Int) {
        if index < pageCount {
            removeTimer()
            indexForTimer = index + orginPageCount
            let point = CGPoint(x: mainPageSize.width * CGFloat(index + orginPageCount), y: 0)
            scrollView.setContentOffset(point, animated: true)
            setPages(at: scrollView.contentOffset)
            refreshVisiblePageAppearance()
            addTimer()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if needsReload {
            orginPageCount = 0
            if let dataSource = dataSource {
                orginPageCount = dataSource.numberOfItems(inCarousel: self)
                pageCount = orginPageCount == 1 ? 1 : orginPageCount * 3
            }
            reusablePages.removeAll()
            pages.removeAll()
            visibleRange = NSRange(location: 0, length: 0)
            
            for _ in 0..<pageCount {
                pages.append(nil)
            }
            
            scrollView.frame = CGRect(x: 0, y: 0, width: mainPageSize.width, height: mainPageSize.height)
            scrollView.contentSize = CGSize(width: mainPageSize.width * CGFloat(pageCount), height: mainPageSize.height)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            scrollView.center = center
            
            if orginPageCount > 1 {
                let x = mainPageSize.width * CGFloat(orginPageCount)
                scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
                indexForTimer = orginPageCount
                addTimer()
            }
            needsReload = false
        }
        setPages(at: scrollView.contentOffset)
        refreshVisiblePageAppearance()
    }
    
    fileprivate lazy var scrollView: UIScrollView = {
        let carousel = UIScrollView()
        carousel.scrollsToTop = false
        carousel.delegate = self
        carousel.isPagingEnabled = true
        carousel.clipsToBounds = false
        carousel.showsVerticalScrollIndicator = false
        carousel.showsHorizontalScrollIndicator = false
        return carousel
    }()
    fileprivate var needsReload = true
    fileprivate var pageCount = 0
    fileprivate var orginPageCount = 0
    fileprivate var p_currentIndex = 0
    fileprivate var visibleRange = NSRange(location: 0, length: 0)
    fileprivate var pages = [UIView?]()
    fileprivate var reusablePages = [UIView]()
    fileprivate var timer: Timer?
    fileprivate var indexForTimer = 0
    
    deinit {
        timer?.invalidate()
    }
    
}

public extension  PagesCarousel {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard orginPageCount > 0 else {
            return
        }
        let number = scrollView.contentOffset.x / mainPageSize.width
        var pageIndex =  Int(floor(number)) % orginPageCount
        
        if orginPageCount > 1 {
            if number >= CGFloat(2 * orginPageCount) {
                let point = CGPoint(x: mainPageSize.width * CGFloat(orginPageCount), y: 0)
                scrollView.setContentOffset(point, animated: false)
                indexForTimer = orginPageCount
            }
            if number <= CGFloat(orginPageCount - 1) {
                let point = CGPoint(x: mainPageSize.width * CGFloat(2 * orginPageCount - 1), y: 0)
                scrollView .setContentOffset(point, animated: false)
                indexForTimer = 2 * orginPageCount
            }
        } else {
            pageIndex = 0
        }
        
        setPages(at: scrollView.contentOffset)
        refreshVisiblePageAppearance()
        if p_currentIndex != pageIndex {
            delegate?.didScrolled?(to: pageIndex, in: self)
        }
        p_currentIndex = pageIndex
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        removeTimer()
    }
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if orginPageCount > 1 && autoScrollInterval > 0 {
            addTimer()
            let number = Int(floor(scrollView.contentOffset.x / mainPageSize.width))
            if indexForTimer == number {
                indexForTimer = number + 1
            } else {
                indexForTimer = number
            }
        }
    }
}

fileprivate extension PagesCarousel {
    func p_setUp() {
        let scrollViewContainner = UIView(frame: bounds)
        scrollViewContainner.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.frame = bounds
        scrollViewContainner.addSubview(scrollView)
        addSubview(scrollViewContainner)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pagesTapedAction(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func pagesTapedAction(_ sender : UITapGestureRecognizer) {
        if sender.state == .ended {
            delegate?.didSelectedCurrentPage?(in: self)
        }
    }
    
    func addTimer() {
        if orginPageCount > 1 && autoScrollInterval > 0 {
            timer = Timer.scheduledTimer(timeInterval: autoScrollInterval, target: self, selector: #selector(autoScrollToNextPage), userInfo: nil, repeats: true)
        }
    }
    func removeTimer() {
        timer?.invalidate()
    }
    @objc func autoScrollToNextPage() {
        indexForTimer += 1
        let point = CGPoint(x: mainPageSize.width * CGFloat(indexForTimer), y: 0)
        scrollView.setContentOffset(point, animated: true)
    }
    func setPages(at contentOffset: CGPoint) {
        let startPoint = CGPoint(x: contentOffset.x - scrollView.frame.origin.x, y: contentOffset.y - scrollView.frame.origin.y)
        let endPoint = CGPoint(x: startPoint.x + bounds.size.width, y: startPoint.y + bounds.size.height)
        var startIndex = 0
        for i in 0..<pages.count {
            if mainPageSize.width * CGFloat(i + 1) > startPoint.x {
                startIndex = i
                break
            }
        }
        var endIndex = startIndex
        for i in startIndex..<pages.count {
            if (mainPageSize.width * CGFloat(i + 1) < endPoint.x && mainPageSize.width * CGFloat(i + 2) >= endPoint.x) || i + 2 == pages.count {
                endIndex = i + 1
                break
            }
        }
        startIndex = max(startIndex, 0)
        endIndex = min(endIndex + 1, pages.count - 1)
        visibleRange = NSRange(location: startIndex, length: endIndex - startIndex + 1)
        for i in startIndex...endIndex {
            setPage(at: i)
        }
        for i in 0..<startIndex {
            removePage(at: i)
        }
        for i in (endIndex + 1)..<pages.count {
            removePage(at: i)
        }
    }
    func refreshVisiblePageAppearance() {
        guard pageScale < 1 && pageScale >= 0 else { return }
        let offset = scrollView.contentOffset.x
        for i in visibleRange.location..<visibleRange.location + visibleRange.length {
            if let page = pages[i] {
                let originX = page.frame.origin.x
                let delta = fabs(originX - offset)
                let originPageFrame = CGRect(x: mainPageSize.width * CGFloat(i), y: 0, width: mainPageSize.width, height: mainPageSize.height)
                var inset = mainPageSize.width * CGFloat(1 - pageScale) * 0.5
                if delta < mainPageSize.width {
                    inset *= (delta / mainPageSize.width)
                }
                let edgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
                page.frame = UIEdgeInsetsInsetRect(originPageFrame, edgeInsets)
            }
        }
    }
    
    func setPage(at index: Int) {
        assert(index >= 0 && index < pages.count)
        var page = pages[index]
        if page == nil {
            if let dataSource = dataSource {
                page = dataSource.carousel(self, pageForItemAt: index % orginPageCount)
                assert(page != nil)
                pages[index] = page
                page!.frame = CGRect(x: mainPageSize.width * CGFloat(index), y: 0, width: mainPageSize.width, height: mainPageSize.height)
                if page!.superview == nil {
                    scrollView.addSubview(page!)
                }
            }
        }
    }
    func removePage(at index: Int) {
        let page = pages[index]
        guard page != nil else {
            return
        }
        queueReusablePage(page!)
        if page!.superview != nil {
            page!.removeFromSuperview()
        }
        pages[index] = nil
        
    }
    func queueReusablePage(_ page: UIView) {
        reusablePages.append(page)
    }
    
}
