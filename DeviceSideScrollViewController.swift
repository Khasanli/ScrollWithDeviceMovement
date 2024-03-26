//
//  DeviceSideScrollViewController.swift
//
//  Created by Khayala Hasanli on 23.03.24.
//

import UIKit
import CoreMotion


class DeviceSideScrollViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let motionManager = CMMotionManager()

    var collectionView : UICollectionView!
    
    var scrolled: Bool = false

    var previusRotation: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupCollectionView()
        setupMotionTracking()
    }
    
    func setupMotionTracking() {

        motionManager.deviceMotionUpdateInterval = 0.1
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] (motion, error) in
                guard let self = self, error == nil, let motion = motion else { return }
                let currentRoll = motion.attitude.roll
               
                
                let rotationChange = RotationDirection.from(currentRoll: currentRoll, previousRoll: self.previusRotation)

                if !self.scrolled {
                    let rotation = abs(currentRoll) - abs(previusRotation)
                    let positiveRotation: CGFloat = abs(currentRoll) + abs(previusRotation)

                    switch rotationChange {
                        case .bothNegative:
                        if rotation > 0.05  && rotation < 0.2 {
                            moveToPrevious()
                        } else if rotation < -0.05 && rotation > -0.2 {
                            moveToNext()
                        }

                        case .bothPositive:
                            if rotation < -0.05 && rotation > -0.2 {
                                moveToPrevious()
                            } else if rotation > 0.05 && rotation < 0.2  {
                                moveToNext()
                            }
                        case .positiveToNegative:
                            if positiveRotation > 0.05 {
                                moveToPrevious()
                            }
                        case .negativeToPositive:
                            if positiveRotation > 0.05 {
                                moveToNext()
                            }
                        case .unchanged:
                            break
                    }
                }
                previusRotation = currentRoll

            }
        }
    }

    func moveToNext() {
        scrolled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.scrolled = false
        })
        
        scrollToNextCell()
    }

    
    func moveToPrevious() {
        scrolled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.scrolled = false
        })

        scrollToPreviousCell()
    }

    
    func setupCollectionView() {
        let layout = CarouselFlowLayout()
        layout.itemSize = CGSize(width: 300, height: 200)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .fast
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SideCustomCell.self, forCellWithReuseIdentifier: "SideCustomCell")
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 200),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func scrollToCell(at indexPath: IndexPath, completion: (() -> Void)? = nil) {
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    
    func scrollToNextCell() {
        let visibleCells = collectionView.indexPathsForVisibleItems.sorted()
        guard let lastVisibleCellIndex = visibleCells.last?.row,
              lastVisibleCellIndex < collectionView.numberOfItems(inSection: 0) - 1 else { return }
        
        let nextIndexPath = IndexPath(item: lastVisibleCellIndex, section: 0)
        scrollToCell(at: nextIndexPath)
    }

    func scrollToPreviousCell() {
        let visibleCells = collectionView.indexPathsForVisibleItems.sorted()
        guard let firstVisibleCellIndex = visibleCells.first?.row,
              firstVisibleCellIndex > 0 else { return }
        
        let previousIndexPath = IndexPath(item: firstVisibleCellIndex, section: 0)
        scrollToCell(at: previousIndexPath)
    }

}

class CarouselFlowLayout: UICollectionViewFlowLayout {
    override init() {
           super.init()
           self.sectionInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
       }
       
       required init?(coder aDecoder: NSCoder) {
           super.init(coder: aDecoder)
           self.sectionInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
       }
       
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        let centerX = collectionView!.contentOffset.x + (collectionView!.bounds.width / 2.0)
        attributes?.forEach { layoutAttribute in
            let distance = abs(layoutAttribute.center.x - centerX)
            let scale = distance / collectionView!.bounds.width
            let scaleForCell = 1 - scale * 0.15
            layoutAttribute.transform = CGAffineTransform(scaleX: scaleForCell, y: scaleForCell)
        }
        return attributes
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let targetRect = CGRect(x: proposedContentOffset.x, y: 0, width: collectionView!.bounds.size.width, height: collectionView!.bounds.size.height)
        let attributes = super.layoutAttributesForElements(in: targetRect)!
        
        var offsetAdjustment = CGFloat.greatestFiniteMagnitude
        let horizontalCenter = proposedContentOffset.x + (collectionView!.bounds.width / 2)
        
        for layoutAttributes in attributes {
            let itemHorizontalCenter = layoutAttributes.center.x
            if (abs(itemHorizontalCenter - horizontalCenter) < abs(offsetAdjustment)) {
                offsetAdjustment = itemHorizontalCenter - horizontalCenter
            }
        }
        
        return CGPoint(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
    }
}

extension DeviceSideScrollViewController {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SideCustomCell", for: indexPath) as! SideCustomCell
        cell.label.text = "\(indexPath.row + 1)"
        return cell
    }
}

class SideCustomCell: UICollectionViewCell {

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
        backgroundColor = UIColor.randomPastelColor()
        layer.cornerRadius = 10
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
}

extension UIColor {
    static func randomPastelColor() -> UIColor {
        let baseRed: CGFloat = 1.0
        let baseGreen: CGFloat = 1.0
        let baseBlue: CGFloat = 1.0
        
        let red = (baseRed + CGFloat.random(in: 0...0.2)) / 2.0
        let green = (baseGreen + CGFloat.random(in: 0...0.2)) / 2.0
        let blue = (baseBlue + CGFloat.random(in: 0...0.2)) / 2.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
