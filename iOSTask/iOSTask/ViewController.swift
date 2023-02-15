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
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    
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
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    
    @objc func scanQRCode() {
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession.addInput(input)
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayer.frame = view.layer.bounds
            view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        } catch {
            print("Error creating capture device input: \(error.localizedDescription)")
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject, metadataObj.type == .qr else {
            return
        }
        searchController.searchBar.text = metadataObj.stringValue
        captureSession.stopRunning()
        previewLayer?.removeFromSuperlayer()
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
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
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

