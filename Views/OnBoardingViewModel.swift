//
//  OnBoardingViewModel.swift
//  POV
//
//  Created by Fay  on 23/05/2026.
//

import Foundation

import Combine

import UserNotifications

import UIKit



class OnboardingViewModel: ObservableObject {

    @Published var showOnboarding: Bool = false

    

    private let defaults = UserDefaults.standard

    private let onboardingKey = "hasCompletedOnboarding"

    

    init() {

        showOnboarding = !defaults.bool(forKey: onboardingKey)

    }

    

    func completeOnboarding() {

        defaults.set(true, forKey: onboardingKey)

        showOnboarding = false

        

        // Request notification permission after onboarding

        requestNotificationPermission()

    }

    

    func requestNotificationPermission() {

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in

            if granted {

                DispatchQueue.main.async {

                    UIApplication.shared.registerForRemoteNotifications()

                }

            }

        }

    }

}
