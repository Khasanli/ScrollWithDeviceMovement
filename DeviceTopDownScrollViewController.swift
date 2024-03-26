//
//  DeviceTopDownScrollViewController.swift
//
//  Created by Khayala Hasanli on 22.03.24.
//

import UIKit
import CoreMotion

class DeviceTopDownScrollViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    let motionManager = CMMotionManager()
    var scrolled: Bool = false
    var previusRotation : CGFloat = 0.5
    var collectionView : UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setCollectionView()
        
        motionManager.deviceMotionUpdateInterval = 0.1
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] (motion, error) in
                guard let self, error == nil else { return }
                
                if let attitude = motion?.attitude {
                    
                    let currentRoll = attitude.quaternion.x
                    let rotationChange = RotationDirection.from(currentRoll: currentRoll, previousRoll: previusRotation)

                    if !scrolled {
                        let rotation = abs(currentRoll) - abs(previusRotation)
                        let positiveRotation: CGFloat = abs(currentRoll) + abs(previusRotation)

                        switch rotationChange {
                            case .bothNegative:
                                if rotation > 0.05 && rotation < 0.2 {
                                    moveToNext()
                                } else if rotation < -0.05 && rotation > -0.2 {
                                    moveToPrevious()
                                }

                            case .bothPositive:
                                if rotation < -0.05 && rotation > -0.2 {
                                    moveToNext()
                                } else if rotation > 0.05 && rotation < 0.2 {
                                    moveToPrevious()
                                }

                            case .positiveToNegative:
                                if positiveRotation > 0.05 {
                                    moveToNext()
                                }

                            case .negativeToPositive:
                                if positiveRotation > 0.05 {
                                    moveToPrevious()
                                }

                            case .unchanged:
                                break
                        }
                    }

                    
                    previusRotation = currentRoll
                }
            }
        }
    }
    
    private func moveToNext() {
        scrolled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
            guard let self else {return}
            scrolled = false
        })

        moveToNextCell()
    }
    
    private func moveToPrevious() {
        scrolled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
            guard let self else {return}
            scrolled = false
        })
        
        moveToPreviousCell()
    }
    
    private func setCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = UIScreen.main.bounds.size
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = false
        
        collectionView.register(FullScreenColorCell.self, forCellWithReuseIdentifier: "FullScreenColorCell")
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsVerticalScrollIndicator = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FullScreenColorCell", for: indexPath) as! FullScreenColorCell
        cell.label.text = "\(indexPath.row + 1)"
        return cell
    }
    
    @objc func moveToNextCell() {
        guard !collectionView.isDragging, !collectionView.isDecelerating else {
            return
        }

        let sortedIndexPaths = collectionView.indexPathsForVisibleItems.sorted { $0.row < $1.row }
        guard let currentIndexPath = sortedIndexPaths.last else { return }
        let targetOffset = collectionView.bounds.height * CGFloat(currentIndexPath.row + 1)
        collectionView.setContentOffset(CGPoint(x: 0, y: targetOffset), animated: true)
    }

    @objc func moveToPreviousCell() {
        guard !collectionView.isDragging, !collectionView.isDecelerating else {
            return
        }

        let sortedIndexPaths = collectionView.indexPathsForVisibleItems.sorted { $0.row < $1.row }
        guard let currentIndexPath = sortedIndexPaths.first else { return }
        let targetOffset = collectionView.bounds.height * CGFloat(currentIndexPath.row - 1)
        collectionView.setContentOffset(CGPoint(x: 0, y: targetOffset), animated: true)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let pageHeight = UIScreen.main.bounds.size.height
        let currentOffset = scrollView.contentOffset.y
        let targetOffset = targetContentOffset.pointee.y
        var newTargetOffset = targetOffset
        
        if targetOffset > currentOffset {
            newTargetOffset = ceil(currentOffset / pageHeight) * pageHeight
        } else {
            newTargetOffset = floor(currentOffset / pageHeight) * pageHeight
        }
        
        if newTargetOffset < 0 {
            newTargetOffset = 0
        } else if newTargetOffset > scrollView.contentSize.height {
            newTargetOffset = scrollView.contentSize.height
        }
        
        targetContentOffset.pointee.y = currentOffset
        scrollView.setContentOffset(CGPoint(x: 0, y: newTargetOffset), animated: true)
    }
}

class FullScreenColorCell: UICollectionViewCell {
    
    let label : UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textColor = .white
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        backgroundColor = generateRandomColor()
        setLabel()
    }
    
    private func setLabel() {
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.widthAnchor.constraint(equalTo: widthAnchor, constant: -50)
        ])
    }
    
    private func generateRandomColor() -> UIColor {
        UIColor(red: .random(in: 0...1),
                green: .random(in: 0...1),
                blue: .random(in: 0...1),
                alpha: 1.0)
    }
}
