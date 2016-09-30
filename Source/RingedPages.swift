//
//  RingedPages.swift
//  RingedPages
//
//  Created by admin on 16/9/28.
//  Copyright © 2016年 Ding. All rights reserved.
//

import UIKit

public enum RPPageControlPositon: Int {
    case bellowBody, inBodyBottom, inBodyTop, aboveBody
}

public protocol RingedPagesDataSource {
    func numberOfItems(in ringedPages: RingedPages) -> Int
    func ringedPages(_ pages: RingedPages, viewForItemAt index: Int) -> UIView
}
@objc public protocol RingedPagesDelegate {
    @objc optional func didSelectedCurrentPage(in pages: RingedPages)
    @objc optional func didScrolled(to index: Int, in pages: RingedPages)
}


open class RingedPages: UIView, PagesCarouselDataSource, PagesCarouselDelegate {
    /// PageControl
    open var showPageControl = true
    open var pageControlPosition = RPPageControlPositon.bellowBody
    open var pageControlHeight:CGFloat = 15
    open var pageControlMarginTop: CGFloat = 5
    open var pageControlMarginBottom: CGFloat = 5
    open var pageControl: ImagePageControl {
        get {
            return m_pageControl
        }
    }
    
    /// Carousel - mian view
    open var carousel: PagesCarousel {
        get {
            return m_carousel
        }
    }
    
    /// Data source and delegate
    open var dataSource: RingedPagesDataSource?
    open var delegate: RingedPagesDelegate?
    
    /// Main API
    open var currentIndex: Int {
        get {
            return carousel.currentIndex
        }
    }
    open func scroll(to index: Int) {
        carousel.scroll(to: index)
    }
    open func reloadData() {
        layoutPageControlAndCarousel()
        carousel.reloadData()
    }
    open func dequeueReusablePage() -> UIView? {
        return carousel.dequeueReusablePage()
    }
    
    fileprivate lazy var m_pageControl: ImagePageControl = {
        let pageControl = ImagePageControl()
        pageControl.addTarget(self, action: #selector(pageControlTapped), for: .valueChanged)
        return pageControl
    }()
    fileprivate lazy var m_carousel: PagesCarousel = {
        let carousel = PagesCarousel()
        carousel.dataSource = self
        carousel.delegate = self
        return carousel
    }()
}

public extension RingedPages {
    public func numberOfItems(inCarousel carousel: PagesCarousel) -> Int {
        if let number = dataSource?.numberOfItems(in: self) {
            return number
        }
        return 0
    }
    public func carousel(_ carousel: PagesCarousel, pageForItemAt index: Int) -> UIView {
        if let page = dataSource?.ringedPages(self, viewForItemAt: index) {
            return page
        }
        return UIView()
    }
    public func didScrolled(to index: Int, in carousel: PagesCarousel) {
        if pageControl.currentIndex != index {
            pageControl.currentIndex = index
        }
        delegate?.didScrolled?(to: index, in: self)
    }
    public func didSelectedCurrentPage(in carousel: PagesCarousel) {
        delegate?.didSelectedCurrentPage?(in: self)
    }    
}

fileprivate extension RingedPages {
    @objc func pageControlTapped(_ pageControl: ImagePageControl) {
        let index = pageControl.currentIndex
        carousel.scroll(to: index)
    }
    func layoutPageControlAndCarousel() {
        layoutIfNeeded()
        pageControl.numberOfPages = 0
        pageControl.removeFromSuperview()
        carousel.removeFromSuperview()
        let num = dataSource?.numberOfItems(in: self)
        guard num != nil && num! > 0 else {
            return
        }
        let number = num!
        pageControl.numberOfPages = number
        pageControl.currentIndex = 0
        var carouselFrame = CGRect.zero
        var pageControlFrame = CGRect.zero
        let size = frame.size
        let pageControlSpaceHeight = pageControlMarginBottom + pageControlMarginTop + pageControlHeight
        switch pageControlPosition {
        case .aboveBody:
            pageControlFrame = CGRect(x: 0, y: pageControlMarginTop, width: size.width, height: pageControlHeight)
            carouselFrame = CGRect(x: 0, y: pageControlSpaceHeight, width: size.width, height: size.height - pageControlSpaceHeight)
        case .inBodyTop:
            pageControlFrame = CGRect(x: 0, y: pageControlMarginTop, width: size.width, height: pageControlHeight)
            carouselFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        case .inBodyBottom:
            pageControlFrame = CGRect(x: 0, y: size.height - pageControlMarginBottom - pageControlHeight, width: size.width, height: pageControlHeight)
            carouselFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        default:
            pageControlFrame = CGRect(x: 0, y: size.height - pageControlHeight - pageControlMarginBottom, width: size.width, height: pageControlHeight)
            carouselFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height - pageControlSpaceHeight)
        }
        carousel.frame = carouselFrame
        pageControl.frame = pageControlFrame
        addSubview(carousel)
        addSubview(pageControl)
        pageControl.isHidden = false
        if !showPageControl {
            pageControl.isHidden = true
            carousel.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
    }
}
