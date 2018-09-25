//
//  TCVodPlayViewController.swift
//  TXXiaoShiPinDemo
//
//  Created by zpc on 2018/9/24.
//  Copyright © 2018年 tencent. All rights reserved.
//

import UIKit

class TCVodPlayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // MARK: Model
    
    struct Model {
        var id = UUID()
        
        // Add additional properties for your own model here.
    }
    
    /// Example data identifiers.
    private let models = (1...1000).map { _ in
        return Model()
    }
    
    /// An `AsyncFetcher` that is used to asynchronously fetch `DisplayData` objects.
    private let asyncFetcher = AsyncFetcher()
    
    // MARK: SubViews
    
    @IBOutlet weak var tableView: UITableView!

    // MARK: UIViewController overrides
    
    /// - Tag: SetDataSources
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: UICollectionViewDataSourcePrefetching
    
    /// - Tag: Prefetching
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // Begin asynchronously fetching data for the requested index paths.
        for indexPath in indexPaths {
            let model = models[indexPath.row]
            asyncFetcher.fetchAsync(model.id)
        }
    }
    
    /// - Tag: CancelPrefetching
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        // Cancel any in-flight requests for data for the specified index paths.
        for indexPath in indexPaths {
            let model = models[indexPath.row]
            asyncFetcher.cancelFetch(model.id)
        }
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TCPlayViewCell.reuseIdentifier, for: indexPath) as? TCPlayViewCell else {
            fatalError("Expected `\(TCPlayViewCell.self)` type for reuseIdentifier \(TCPlayViewCell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        
        let model = models[indexPath.row]
        let id = model.id
        cell.representedId = id
        
        // Check if the `asyncFetcher` has already fetched data for the specified identifier.
        if let fetchedData = asyncFetcher.fetchedData(for: id) {
            // The data has already been fetched and cached; use it to configure the cell.
            cell.configure(with: fetchedData)
        } else {
            // There is no data available; clear the cell until we've fetched data.
            cell.configure(with: nil)
            
            // Ask the `asyncFetcher` to fetch data for the specified identifier.
            asyncFetcher.fetchAsync(id) { fetchedData in
                DispatchQueue.main.async {
                    /*
                     The `asyncFetcher` has fetched data for the identifier. Before
                     updating the cell, check if it has been recycled by the
                     collection view to represent other data.
                     */
                    guard cell.representedId == id else { return }
                    
                    // Configure the cell with the fetched image.
                    cell.configure(with: fetchedData)
                }
            }
        }
        
        return cell
    }
    
}


