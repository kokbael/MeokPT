//
//  CameraScannerView.swift
//  MeokPT
//
//  Created by 김동영 on 5/22/25.
//

import SwiftUI
import AVFoundation

struct CameraScannerView: UIViewControllerRepresentable {
    var didFindCode: (String) -> Void
    var didFailScanning: (ScannerError) -> Void
    var didPermissionDenied: (Bool) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerViewController = ScannerViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(didFindCode: didFindCode, didFailScanning: didFailScanning, didPermissionDenied: didPermissionDenied)
    }

    class Coordinator: NSObject, ScannerViewControllerDelegate {
        var didFindCode: (String) -> Void
        var didFailScanning: (ScannerError) -> Void
        var didPermissionDenied: (Bool) -> Void

        init(didFindCode: @escaping (String) -> Void, didFailScanning: @escaping (ScannerError) -> Void, didPermissionDenied: @escaping (Bool) -> Void) {
            self.didFindCode = didFindCode
            self.didFailScanning = didFailScanning
            self.didPermissionDenied = didPermissionDenied
        }

        func didFindBarcode(code: String) {
            didFindCode(code)
        }
        
        func didFail(error: ScannerError) {
            didFailScanning(error)
        }
        
        func didPermissionDenied(shouldShowAlert: Bool) {
            didPermissionDenied(shouldShowAlert)
        }
    }
}
