//
//  JellySlider+Rx.swift
//  BEKApps.com
//
//  Created by Behrad Kazemi on 9/14/19.
//  Copyright © 2019 Behrad Kazemi. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension Reactive where Base: JellySlider {
	
	
	/// Reactive wrapper for `value` property.
	public var value: ControlProperty<Float> {
		return controlProperty(
			editingEvents: [.allEditingEvents, .valueChanged],
			getter: { slider in
				slider.progress
		},
			setter: { slider, value in
				slider.progress = value
		})
	}
}
