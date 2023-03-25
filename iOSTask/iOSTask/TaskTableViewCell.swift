//
//  TaskTableViewCell.swift
//  iOSTask
//
//  Created by Mert Duran on 14.02.2023.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    static let reuseIdentifier = "TaskTableViewCell"
    
    let taskLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let colorView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        contentView.addSubview(colorView)
        colorView.widthAnchor.constraint(equalToConstant: 10).isActive = true
        colorView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        contentView.addSubview(taskLabel)
        taskLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 16).isActive = true
        taskLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
        taskLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        
        contentView.addSubview(titleLabel)
        titleLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 16).isActive = true
        titleLabel.topAnchor.constraint(equalTo: taskLabel.bottomAnchor, constant: 8).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        
        contentView.addSubview(descriptionLabel)
        descriptionLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 16).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
    }
    
    func configure(with task: Task) {
        taskLabel.text = task.task
        titleLabel.text = task.title
        descriptionLabel.text = task.description
        if let color = UIColor(hex: task.colorCode) {
            colorView.backgroundColor = color
        }
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.count != 6 {
            return nil
        }
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

