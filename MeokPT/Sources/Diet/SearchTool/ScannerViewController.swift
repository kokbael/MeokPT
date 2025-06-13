//
//  ScannerViewController.swift
//  MeokPT
//
//  Created by 김동영 on 5/22/25.
//

import UIKit
import AVFoundation

protocol ScannerViewControllerDelegate: AnyObject {
    func didFindBarcode(code: String)
    func didFail(error: ScannerError)
    func didPermissionDenied(shouldShowAlert: Bool)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    weak var delegate: ScannerViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        checkCameraPermissions()
    }

    private func checkCameraPermissions() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        // 사용자가 권한 요청을 거부 - 직접 알림 표시
                        self?.showPermissionAlert()
                    }
                }
            }
        case .denied:
            // 이미 권한이 거부된 상태 - 직접 알림 표시
            DispatchQueue.main.async { [weak self] in
                self?.showPermissionAlert()
            }
        case .restricted:
            delegate?.didFail(error: .noPermission("카메라 접근이 제한되어 있습니다."))
        @unknown default:
            delegate?.didFail(error: .unknownError)
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "카메라 권한 필요",
            message: "바코드를 스캔하여 식품 정보를 조회하기 위해 카메라 권한이 필요합니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { [weak self] _ in
            self?.delegate?.didPermissionDenied(shouldShowAlert: false)
        })
        
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { [weak self] _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            self?.delegate?.didPermissionDenied(shouldShowAlert: false)
        })
        
        present(alert, animated: true)
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.didFail(error: .noCameraAvailable)
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.didFail(error: .inputFailed)
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            delegate?.didFail(error: .inputFailed)
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            // 지원할 바코드 유형 설정 (필요에 따라 추가/수정)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13]
        } else {
            delegate?.didFail(error: .metadataOutputFailed)
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        startRunningSession()
    }
    
    func startRunningSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (captureSession?.isRunning == false) {
            startRunningSession()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            delegate?.didFindBarcode(code: stringValue)
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
