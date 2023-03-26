//
//  ViewController.swift
//  iOSTask
//
//  Created by Mert Duran on 10.02.2023.
//

import UIKit
import AVFoundation

struct Task: Codable {
    let task: String
    let title: String
    let description: String
    let colorCode: String
    
    init(json: [String: Any]) {
        task = json["task"] as? String ?? ""
        title = json["title"] as? String ?? ""
        description = json["description"] as? String ?? ""
        colorCode = json["colorCode"] as? String ?? ""
    }
}

class ViewController: UIViewController, UISearchResultsUpdating, AVCaptureMetadataOutputObjectsDelegate {
    
    let tableView = UITableView()
    var tasks: [Task] = []
    var filteredTasks: [Task] = []
    let refreshControl = UIRefreshControl()
    let searchController = UISearchController(searchResultsController: nil)
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        fetchData()
        setupSearchBar()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.addSubview(refreshControl)
        tableView.sendSubviewToBack(refreshControl)
        if let savedTasks = UserDefaults.standard.data(forKey: "tasks") {
            let decoder = JSONDecoder()
            if let loadedTasks = try? decoder.decode([Task].self, from: savedTasks) {
                tasks = loadedTasks
            }
        }
        let qrCodeButton = UIBarButtonItem(title: "Scan QR Code", style: .plain, target: self, action: #selector(scanQRCode))
        navigationItem.rightBarButtonItem = qrCodeButton
    }
    func fetchData() {
        if let savedTasks = UserDefaults.standard.data(forKey: "tasks") {
            let decoder = JSONDecoder()
            if let loadedTasks = try? decoder.decode([Task].self, from: savedTasks) {
                tasks = loadedTasks
                filteredTasks = loadedTasks
                tableView.reloadData()
                return
            }
        }
        performLoginRequest { result in
            switch result {
            case .success:
                self.requestTasks()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func requestTasks() {
        iOSTask.requestTasks(accessToken: ConfigAccess.accessToken) { (response, tasks, error) in
            if let error = error {
                print(error)
                return
            }
            guard let tasks = tasks else {
                print("No tasks found")
                return
            }
            self.tasks = tasks
            self.filteredTasks = tasks
            
            self.saveTasksToUserDefaults() // Save the updated tasks array
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    @objc func scanQRCode() {
        searchController.searchBar.text = ""
        view.backgroundColor = UIColor.black
        self.getCameraPreview()
    }
    
    func getCameraPreview(){
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            }   catch   {
            return
            }
        if (captureSession.canAddInput(videoInput)){
            captureSession.addInput(videoInput)
        } else {
            showAlert()
            return
        }
        let metadataOutput = AVCaptureMetadataOutput()
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            showAlert()
            return
        }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer) // add preview layer to your view
        captureSession.startRunning() // start capturing
    }
    
    func showAlert() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device doesn't support for scanning a QR code. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning() // stop scanning after receiving metadata output
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let codeString = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            searchController.searchBar.text = codeString
            previewLayer?.removeFromSuperlayer()
        }
    }
    
    func receivedCode(qrcode: String) {
        searchController.searchBar.text = qrcode
        print(qrcode)
        let alertController = UIAlertController(title: "Success", message: qrcode, preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Ok", style: .default) { (action:UIAlertAction) in
            self.dismiss(animated: true)
            
            
        }
        alertController.addAction(action1)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self // HMM?
        tableView.register(TaskTableViewCell.self, forCellReuseIdentifier: "TaskTableViewCell")
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    func setupSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Task?"
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    @objc func refreshData() {
        iOSTask.requestTasks(accessToken: ConfigAccess.accessToken) { [weak self] (response, tasks, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error: \(error)")
                return
            }
            guard let tasks = tasks else {
                print("Error: No tasks found")
                return
            }
            self.tasks = tasks
            self.filteredTasks = tasks
            
            self.saveTasksToUserDefaults() // Save the updated tasks array
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func saveTasksToUserDefaults() {
        let encoder = JSONEncoder()
        if let encodedTasks = try? encoder.encode(tasks) {
            UserDefaults.standard.set(encodedTasks, forKey: "tasks")
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredTasks = tasks.filter({( task : Task) -> Bool in
                return task.task.lowercased().contains(searchText.lowercased())
            })
        } else {
            filteredTasks = tasks
        }
        tableView.reloadData()
    }
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredTasks.count : tasks.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TaskTableViewCell.reuseIdentifier, for: indexPath) as! TaskTableViewCell
        let task = searchController.isActive ? filteredTasks[indexPath.row] : tasks[indexPath.row]
        cell.configure(with: task)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}
extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredTasks = tasks
        } else {
            filteredTasks = tasks.filter { task in
                return task.task.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

