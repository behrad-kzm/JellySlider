//
//  JellySlider+Rx.swift
//  Playor
//
//  Created by Behrad Kazemi on 9/14/19.
//  Copyright © 2019 Behrad Kazemi. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension Reactive where Base: JellySlider {
	
	
	/// Reactive wrapper for `value` property.
	public var value: Binder<Float> {
		return Binder(self.base) { slider, progress in
			let progress = max(0.0, min(progress, 1.0))
			slider.setProgress(progress: CGFloat(progress))
		}
	}
	
}
