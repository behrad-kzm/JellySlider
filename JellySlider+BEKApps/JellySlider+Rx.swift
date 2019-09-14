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
	public var value: ControlProperty<CGFloat> {
		return controlProperty(
			editingEvents: [.allEditingEvents, .valueChanged],
			getter: { slider in
				slider.value
		},
			setter: { slider, value in
				slider.setProgress(progress: value)
		})
	}
}
