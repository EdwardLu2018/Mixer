//
//  ViewController+CardView.swift
//  Mixer
//
//  Created by Edward on 12/16/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import UIKit

extension ViewController {

    enum SongVCState {
        case expanded
        case collapsed
    }
    
    @objc
    func handleDataPan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startTransition(state: nextSongVCState(), duration: 1.0)
        case .changed:
            let translation = recognizer.translation(in: self.songViewController.handleArea)
            var fractionComplete = translation.y / songVCHeight
            fractionComplete = songVCVisible ? fractionComplete : -fractionComplete
            updateTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueTransition()
        default:
            break
        }
    }
    
    func setUpSongViewController() {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        self.view.addSubview(visualEffectView)
        self.view.sendSubviewToBack(visualEffectView)
        
        if let songViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SongView") as? SongViewController {
            self.songViewController = songViewController
            self.addChild(songViewController)
            self.view.addSubview(songViewController.view)
            
            let offset: CGFloat = 10
            songViewController.view.frame = CGRect(x: offset/2, y: self.view.frame.height - songVCHandleArea, width: self.view.bounds.width - offset, height: songVCHeight)
            
            songViewController.view.clipsToBounds = true
            songViewController.view.layer.cornerRadius = 10
            
            panGestureRecognizer = UIPanGestureRecognizer()
            panGestureRecognizer.addTarget(self, action: #selector(handleDataPan))
            songViewController.handleArea.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    func nextSongVCState() -> SongVCState {
        return songVCVisible ? .collapsed : .expanded
    }
    
    func animateTransitionIfNeeded(state: SongVCState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.85) {
                switch state {
                case .expanded:
                    self.songViewController.view.frame.origin.y = self.view.frame.height - self.songVCHeight
                case .collapsed:
                    self.songViewController.view.frame.origin.y = self.view.frame.height - self.songVCHandleArea
                }
            }
            frameAnimator.addCompletion { _ in
                self.songVCVisible = !self.songVCVisible
                self.runningAnimations.removeAll()
            }
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    self.songViewController.view.layer.cornerRadius = 15
                case .collapsed:
                    self.songViewController.view.layer.cornerRadius = 10
                }
            }
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                    
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
            
            let rotateAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.songViewController.swipeUpImage.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                case .collapsed:
                    self.songViewController.swipeUpImage.transform = CGAffineTransform(rotationAngle: 0)
                }
            }
            rotateAnimator.startAnimation()
            runningAnimations.append(rotateAnimator)
        }
    }
    
    func startTransition(state: SongVCState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateTransition(fractionCompleted: CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueTransition() {
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
}
