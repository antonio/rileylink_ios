//
//  OmnipodReservoirView.swift
//  OmniKit
//
//  Created by Pete Schwamb on 10/22/18.
//  Copyright © 2018 Pete Schwamb. All rights reserved.
//

import UIKit
import LoopKitUI
import OmniKit

public final class OmnipodReservoirView: LevelHUDView, NibLoadable {

    @IBOutlet private weak var volumeLabel: UILabel!
    
    @IBOutlet private weak var alertLabel: UILabel! {
        didSet {
            alertLabel.alpha = 0
            alertLabel.textColor = UIColor.white
            alertLabel.layer.cornerRadius = 9
            alertLabel.clipsToBounds = true
        }
    }
    
    public class func instantiate() -> OmnipodReservoirView {
        return nib().instantiate(withOwner: nil, options: nil)[0] as! OmnipodReservoirView
    }

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.alpha = 0.0
        self.isHidden = true
        volumeLabel.isHidden = true
    }

    public var reservoirLevel: Double? {
        didSet {
            if oldValue == nil && reservoirLevel != nil {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 1, animations: {
                        self.alpha = 1.0
                        self.isHidden = false
                    })
                }
            }
            level = reservoirLevel

            switch reservoirLevel {
            case .none:
                volumeLabel.isHidden = true
            case let x? where x > 0.25:
                volumeLabel.isHidden = true
            case let x? where x > 0.10:
                volumeLabel.textColor = tintColor
                volumeLabel.isHidden = false
            default:
                volumeLabel.textColor = tintColor
                volumeLabel.isHidden = false
            }
        }
    }
    
    private func updateColor() {
        switch reservoirAlertState {
        case .lowReservoir, .empty:
            alertLabel.backgroundColor = stateColors?.warning
        case .ok:
            alertLabel.backgroundColor = stateColors?.normal
        }
    }
    
    private var reservoirAlertState = ReservoirAlertState.ok {
        didSet {
            var alertLabelAlpha: CGFloat = 1
            
            switch reservoirAlertState {
            case .ok:
                alertLabelAlpha = 0
            case .lowReservoir, .empty:
                alertLabel.text = "!"
            }
            
            updateColor()
            
            print("setting alert state to: \(reservoirAlertState)")
            UIView.animate(withDuration: 0.25, animations: {
                self.alertLabel.alpha = alertLabelAlpha
            })
        }
    }

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        return formatter
    }()

    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        return formatter
    }()

    private func setReservoirVolume(volume: Double, at date: Date) {
        if let units = numberFormatter.string(from: volume) {
            volumeLabel.text = String(format: LocalizedString("%@U", comment: "Format string for reservoir volume. (1: The localized volume)"), units)
            let time = timeFormatter.string(from: date)
            caption?.text = time

            accessibilityValue = String(format: LocalizedString("%1$@ units remaining at %2$@", comment: "Accessibility format string for (1: localized volume)(2: time)"), units, time)
        }
    }
}

extension OmnipodReservoirView: ReservoirVolumeObserver {
    public func reservoirStateDidChange(_ units: Double, at validTime: Date, level: Double?, reservoirAlertState: ReservoirAlertState) {
        DispatchQueue.main.async {
            self.reservoirLevel = level
            self.setReservoirVolume(volume: units, at: validTime)
            self.reservoirAlertState = reservoirAlertState
        }
    }
}

