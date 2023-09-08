//
//  adMovBannerView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/08/20.
//

import SwiftUI
import UIKit // こちらも必要
import GoogleMobileAds // 忘れずに

struct AdMobBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner) // インスタンスを生成
        // 諸々の設定をしていく
        //本番用
        banner.adUnitID = "ca-app-pub-5529798279445729/9711244261"
        
        //テスト用
//        banner.adUnitID = "app-pub-3940256099942544/2934735716"
        
        
        banner.rootViewController = UIApplication.shared.windows.first?.rootViewController
        banner.load(GADRequest())
        return banner // 最終的にインスタンスを返す
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
      // 特にないのでメソッドだけ用意
    }
}
